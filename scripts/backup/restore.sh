#!/usr/bin/env bash
# Spielt eine entschlüsselte Sicherung (Ordner mit roles.sql, schema.sql, data.sql) in eine LEERE Datenbank ein,
# nach der Supabase-Anleitung „Backup and restore using CLI“.
# Ziel: neues Supabase-Projekt (Desaster Recovery) oder lokaler Stack (Probe). Nie vereins-os-test: keine Echtdaten in TEST.
# Aufruf: RESTORE_DB_URL='<Verbindung>' scripts/backup/restore.sh <Ordner>
# Ohne Rückfrage nur mit RESTORE_CONFIRM=ja.
set -euo pipefail

dir="${1:?Ordner der Sicherung fehlt}"
: "${RESTORE_DB_URL:?RESTORE_DB_URL fehlt}"
for f in roles.sql schema.sql data.sql; do
  test -s "$dir/$f" || { echo "$dir/$f fehlt oder ist leer." >&2; exit 1; }
done

target="$(sed -E 's#^[^@]*@##; s#/.*$##' <<<"$RESTORE_DB_URL")"
tables="$(psql "$RESTORE_DB_URL" -X -At -v ON_ERROR_STOP=1 \
  -c "select count(*) from information_schema.tables where table_schema = 'public'")"
if [[ "$tables" != 0 ]]; then
  echo "Abbruch: Das Ziel $target hat schon $tables Tabellen in public. Nur in eine leere Datenbank einspielen." >&2
  exit 1
fi

if [[ "${RESTORE_CONFIRM:-}" != ja ]]; then
  if [[ ! -t 0 ]]; then
    echo "Abbruch: ohne Terminal nur mit RESTORE_CONFIRM=ja." >&2
    exit 1
  fi
  read -r -p "Echtdaten aus $dir in $target einspielen? Nie in vereins-os-test. Zum Bestätigen ja eingeben: " answer
  [[ "$answer" == ja ]] || { echo "Abgebrochen."; exit 1; }
fi

psql "$RESTORE_DB_URL" -X -q --single-transaction -v ON_ERROR_STOP=1 \
  --file "$dir/roles.sql" \
  --file "$dir/schema.sql" \
  --command 'SET session_replication_role = replica' \
  --file "$dir/data.sql"
echo "Sicherung in $target eingespielt."
