#!/usr/bin/env bash
# Lokaler Stack für die Screenshots der Anleitung: Supabase lokal (nie TEST, nie PROD), Seed mit EZ und FI,
# alle umgesetzten Module freigeschaltet (nur lokal) und die App unter http://localhost:5173.
#
# Aufruf aus dem Repo-Wurzelverzeichnis:
#   SEED_TEST_PASSWORD=… scripts/anleitung/lokaler-stack.sh
#   SEED_TEST_PASSWORD=… npm run anleitung:screenshots -- --vorbereiten
#
# supabase/config.toml schaltet die Registrierung per E-Mail ab; der lokale Auth-Dienst lehnt damit auch die
# Anmeldung mit Passwort ab. Das Skript erlaubt sie nur für den Start des lokalen Stacks und stellt die Datei danach
# wieder her (die Änderung wird nie committet).
set -euo pipefail

cd "$(dirname "$0")/../.."

[[ -n "${SEED_TEST_PASSWORD:-}" ]] || { echo "SEED_TEST_PASSWORD fehlt (frei wählbar, nur lokal)." >&2; exit 1; }

# Docker: in Cloud-Sitzungen läuft der Daemon nicht von selbst
if ! docker info >/dev/null 2>&1; then
  command -v dockerd >/dev/null || { echo "Docker läuft nicht." >&2; exit 1; }
  (dockerd >/tmp/dockerd.log 2>&1 &)
  for _ in $(seq 60); do docker info >/dev/null 2>&1 && break; sleep 1; done
  docker info >/dev/null 2>&1 || { echo "Docker startet nicht (siehe /tmp/dockerd.log)." >&2; exit 1; }
fi

# Anmeldung per E-Mail nur für den lokalen Start erlauben
cp supabase/config.toml /tmp/vereins-os-config.toml
trap 'cp /tmp/vereins-os-config.toml supabase/config.toml' EXIT
sed -i.bak '/^\[auth.email\]/,/^\[/ s/^enable_signup = false/enable_signup = true/' supabase/config.toml
rm -f supabase/config.toml.bak

# Frischer Stack ohne alte Daten; der Seed ist idempotent, aber Reste früherer Läufe sollen nicht in die Bilder
npx supabase stop --no-backup >/dev/null 2>&1 || true
npx supabase start -x studio,imgproxy,vector,logflare,edge-runtime,supavisor,postgres-meta
cp /tmp/vereins-os-config.toml supabase/config.toml

status="$(npx supabase status -o json)"
db_url="$(node -e 'console.log(JSON.parse(process.argv[1]).DB_URL)' "$status")"
api_url="$(node -e 'console.log(JSON.parse(process.argv[1]).API_URL)' "$status")"
publishable="$(node -e 'console.log(JSON.parse(process.argv[1]).PUBLISHABLE_KEY)' "$status")"

[[ "$db_url" =~ @(127\.0\.0\.1|localhost): ]] || { echo "Kein lokaler Stack: $db_url" >&2; exit 1; }

SEED_DB_URL="$db_url" SEED_WITH_EZ=1 SEED_WITH_FI=1 supabase/seed.sh

# Für die Bilder alle Module mit Oberfläche zeigen; den echten Stand nennt die Tabelle in docs/anleitung/README.md
psql "$db_url" -q -c "update public.ad_modules set is_available = true where code in ('AD', 'EA', 'GR', 'EZ', 'FI', 'TK')"

# App gegen den lokalen Stack (Publishable Key des lokalen Stacks, kein Secret)
pkill -f "vite --port 5173" 2>/dev/null || true
VITE_SUPABASE_URL="$api_url" VITE_SUPABASE_ANON_KEY="$publishable" \
  nohup npx vite --port 5173 --strictPort >/tmp/vereins-os-vite.log 2>&1 &
for _ in $(seq 60); do curl -sf http://localhost:5173 >/dev/null && break; sleep 1; done
curl -sf http://localhost:5173 >/dev/null || { echo "App startet nicht (siehe /tmp/vereins-os-vite.log)." >&2; exit 1; }

echo "Bereit: http://localhost:5173 (lokaler Stack). Weiter mit: npm run anleitung:screenshots -- --vorbereiten"
