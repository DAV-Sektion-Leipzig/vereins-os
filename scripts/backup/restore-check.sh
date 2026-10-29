#!/usr/bin/env bash
# Probe-Wiederherstellung einer Sicherung in einen frischen lokalen Supabase-Stack (Docker) mit anschließendem
# Vergleich der Zeilenzahlen. Läuft in der GitHub Action nach jeder Sicherung, lokal für die vierteljährliche Probe.
# Ausgaben von psql gehen nur in die Protokolldatei (sie können Inhalte enthalten); auf der Konsole steht
# nur das Ergebnis.
# Aufruf: scripts/backup/restore-check.sh <Ordner der Sicherung> <Protokolldatei>
set -euo pipefail

dir="$(cd "${1:?Ordner der Sicherung fehlt}" && pwd)"
log="${2:?Protokolldatei fehlt}"
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
: > "$log"

# Postgres-Hauptversion wie in der Sicherung (info.txt), sonst wie im Repository
major="$(sed -n 's/^server_version_num: \([0-9]*\)$/\1/p' "$dir/info.txt" 2>/dev/null || true)"
major="${major:+$((major / 10000))}"
major="${major:-$(sed -n 's/^major_version = \([0-9]*\)/\1/p' "$here/../../supabase/config.toml")}"

cleanup() { (cd "$work" && supabase stop --no-backup >/dev/null 2>&1) || true; rm -rf "$work"; }
trap cleanup EXIT

cd "$work"
supabase init --force </dev/null >>"$log" 2>&1
sed -i.bak "s/^project_id = .*/project_id = \"backup-probe\"/; s/^major_version = .*/major_version = $major/" supabase/config.toml
echo "Starte lokalen Stack (Postgres $major) …"
supabase start -x studio,imgproxy,edge-runtime,logflare,vector >>"$log" 2>&1
db_url="$(supabase status -o env | sed -n 's/^DB_URL="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p')"
test -n "$db_url"

echo "Spiele Sicherung ein …"
if ! RESTORE_CONFIRM=ja RESTORE_DB_URL="$db_url" "$here/restore.sh" "$dir" >>"$log" 2>&1; then
  # Fehlermeldung ohne Werte: alles in Klammern und Anführungszeichen ausblenden
  grep -m1 -E 'ERROR|FATAL|Abbruch' "$log" | sed -E 's/\([^)]*\)/(…)/g; s/"[^"]*"/"…"/g; s/'"'"'[^'"'"']*'"'"'/'"'"'…'"'"'/g' >&2 || true
  echo "Probe-Wiederherstellung fehlgeschlagen. Vollständiges Protokoll: $log" >&2
  exit 1
fi

echo "Vergleiche Zeilenzahlen …"
VERIFY_DB_URL="$db_url" "$here/verify.sh" "$dir/manifest.tsv"
echo "Probe-Wiederherstellung erfolgreich."
