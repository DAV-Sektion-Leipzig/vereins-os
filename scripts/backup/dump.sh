#!/usr/bin/env bash
# Sicherung einer Supabase-Datenbank nach der Supabase-Anleitung „Backup and restore using CLI“:
# roles.sql, schema.sql und data.sql, dazu manifest.tsv (Zeilenzahl je Tabelle) und info.txt.
# Aufruf: BACKUP_DB_URL='<Session-Pooler-Verbindung>' scripts/backup/dump.sh <Zielordner>
# Gibt keine Inhalte aus, weil die Logs der GitHub Action öffentlich sind.
set -euo pipefail

out="${1:?Zielordner fehlt}"
: "${BACKUP_DB_URL:?BACKUP_DB_URL fehlt}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$out"

supabase db dump --db-url "$BACKUP_DB_URL" -f "$out/roles.sql" --role-only
supabase db dump --db-url "$BACKUP_DB_URL" -f "$out/schema.sql"
supabase db dump --db-url "$BACKUP_DB_URL" -f "$out/data.sql" --use-copy --data-only

psql "$BACKUP_DB_URL" -X -q -v ON_ERROR_STOP=1 -At -F $'\t' -f "$here/count-rows.sql" > "$out/manifest.tsv"
{
  echo "erstellt: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "git: ${GITHUB_SHA:-$(git -C "$here" rev-parse HEAD 2>/dev/null || echo unbekannt)}"
  echo "server_version_num: $(psql "$BACKUP_DB_URL" -X -At -c 'show server_version_num')"
} > "$out/info.txt"

for f in roles.sql schema.sql data.sql manifest.tsv; do
  test -s "$out/$f" || { echo "Sicherung unvollständig: $f fehlt oder ist leer." >&2; exit 1; }
done
echo "Sicherung erstellt: $(wc -l < "$out/manifest.tsv") Tabellen, $(du -sh "$out" | cut -f1)."
