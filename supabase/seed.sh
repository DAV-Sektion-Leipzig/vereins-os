#!/usr/bin/env bash
# Seed für den lokalen Stack (CI) und vereins-os-test – nie PROD (spec.md AD Abschnitt 9, US-AD-16).
#
# Benötigt:
#   SEED_TEST_PASSWORD  Passwort der Testzugänge (lokal .env.local, CI: GitHub-Secret)
#   SEED_DB_URL         Postgres-Verbindung zum Ziel (lokal .env.local, CI: DB_URL des lokalen Stacks)
#   SEED_WITH_EZ=1      optional: zusätzlich supabase/seed-ez.sql (Anwesenheitserfassung, nur TEST)
#   SEED_WITH_FI=1      optional: zusätzlich supabase/seed-fi.sql (Finanzen, nur TEST)
#   SEED_WITH_TK=1      optional: zusätzlich supabase/seed-tk.sql (Planungshilfe, nur TEST)
#   SEED_WITH_DS=1      optional: zusätzlich supabase/seed-ds.sql (Bereich Budget des Dashboards, nur TEST)
#   psql
#
# Aufruf aus dem Repo-Wurzelverzeichnis: supabase/seed.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# Project Ref von vereins-os-prod (kein Secret; steht auch in der PROD-URL).
# Solange leer, bricht das Skript bei jeder entfernten Verbindung ab (Schutz).
PROD_PROJECT_REF="bihzvargwycqdpdxysvo"

abort_prod() {
  echo "Seed in PROD nicht erlaubt." >&2
  [[ -n "${1:-}" ]] && echo "($1)" >&2
  exit 1
}

# Lokale Werte nur laden, wenn sie nicht schon gesetzt sind (CI setzt sie selbst).
if [[ ( -z "${SEED_DB_URL:-}" || -z "${SEED_TEST_PASSWORD:-}" ) && -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env.local
  set +a
fi

[[ -n "${SEED_TEST_PASSWORD:-}" ]] || { echo "SEED_TEST_PASSWORD fehlt." >&2; exit 1; }
[[ -n "${SEED_DB_URL:-}" ]] || { echo "SEED_DB_URL fehlt." >&2; exit 1; }

# Ziel bestimmen
if [[ "$SEED_DB_URL" =~ @(127\.0\.0\.1|localhost)(:[0-9]+)?/ ]]; then
  echo "Seed gegen den lokalen Stack."
else
  ref=""
  if [[ "$SEED_DB_URL" =~ @db\.([a-z0-9]{20})\.supabase\.co ]]; then
    ref="${BASH_REMATCH[1]}"
  elif [[ "$SEED_DB_URL" =~ ://postgres\.([a-z0-9]{20})[:@] ]]; then
    ref="${BASH_REMATCH[1]}"
  fi

  [[ -n "$PROD_PROJECT_REF" ]] || abort_prod "PROD_PROJECT_REF in supabase/seed.sh ist nicht gesetzt"
  [[ -n "$ref" ]] || abort_prod "Project Ref in SEED_DB_URL nicht erkennbar"
  [[ "$ref" != "$PROD_PROJECT_REF" ]] || abort_prod
  echo "Seed gegen Projekt $ref."
fi

command -v psql >/dev/null || { echo "psql fehlt (z. B. brew install libpq)." >&2; exit 1; }

psql "$SEED_DB_URL" \
  --single-transaction \
  -v ON_ERROR_STOP=1 \
  -v test_password="$SEED_TEST_PASSWORD" \
  -f supabase/seed.sql

# Testdaten der Anwesenheitserfassung nur auf Wunsch (vereins-os-test), nicht in CI (EZ uebergabe-seed-umsetzung.md)
if [[ "${SEED_WITH_EZ:-}" == "1" ]]; then
  psql "$SEED_DB_URL" --single-transaction -v ON_ERROR_STOP=1 -f supabase/seed-ez.sql
  echo "Seed Anwesenheitserfassung abgeschlossen."
fi

# Testdaten Finanzen nur auf Wunsch (vereins-os-test), nicht in CI (spec.md FI Abschnitt 9)
if [[ "${SEED_WITH_FI:-}" == "1" ]]; then
  psql "$SEED_DB_URL" --single-transaction -v ON_ERROR_STOP=1 -v test_password="$SEED_TEST_PASSWORD" \
    -f supabase/seed-fi.sql
  echo "Seed Finanzen abgeschlossen."
fi

# Testdaten Planungshilfe Touren und Kurse nur auf Wunsch (vereins-os-test), nicht in CI (spec.md TK Abschnitt 9)
if [[ "${SEED_WITH_TK:-}" == "1" ]]; then
  psql "$SEED_DB_URL" --single-transaction -v ON_ERROR_STOP=1 -f supabase/seed-tk.sql
  echo "Seed Planungshilfe abgeschlossen."
fi

# Testdaten Bereich Budget nur auf Wunsch (vereins-os-test), nicht in CI (spec.md DS Abschnitt 9)
if [[ "${SEED_WITH_DS:-}" == "1" ]]; then
  psql "$SEED_DB_URL" --single-transaction -v ON_ERROR_STOP=1 -v test_password="$SEED_TEST_PASSWORD" \
    -f supabase/seed-ds.sql
  echo "Seed Budget abgeschlossen."
fi

# Testdaten Schnittstellen nur auf Wunsch (vereins-os-test), nicht in CI (spec.md SC Abschnitt 9)
if [[ "${SEED_WITH_SC:-}" == "1" ]]; then
  psql "$SEED_DB_URL" --single-transaction -v ON_ERROR_STOP=1 -f supabase/seed-sc.sql
  echo "Seed Schnittstellen abgeschlossen."
fi

echo "Seed abgeschlossen."
