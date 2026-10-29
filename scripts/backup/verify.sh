#!/usr/bin/env bash
# Vergleicht die Zeilenzahlen einer wiederhergestellten Datenbank mit manifest.tsv der Sicherung.
# Fehler, wenn eine Tabelle fehlt oder leer ist, obwohl sie in der Sicherung Zeilen hatte.
# Kleine Abweichungen sind möglich (Zeilenzahlen und Sicherung entstehen nacheinander) und werden nur gemeldet.
# Gibt nur Tabellennamen aus, keine Inhalte und keine Zahlen (öffentliche Logs).
# Aufruf: VERIFY_DB_URL='<Verbindung>' scripts/backup/verify.sh <manifest.tsv>
set -euo pipefail

manifest="${1:?manifest.tsv fehlt}"
: "${VERIFY_DB_URL:?VERIFY_DB_URL fehlt}"
here="$(cd "$(dirname "$0")" && pwd)"

declare -A restored=()
while IFS=$'\t' read -r table count; do
  restored["$table"]="$count"
done < <(psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 -At -F $'\t' -f "$here/count-rows.sql")

checked=0 errors=0 deviations=0
while IFS=$'\t' read -r table count; do
  checked=$((checked + 1))
  if [[ -z "${restored[$table]+x}" ]]; then
    echo "Fehlt nach der Wiederherstellung: $table"; errors=$((errors + 1))
  elif (( count > 0 && restored[$table] == 0 )); then
    echo "Leer nach der Wiederherstellung: $table"; errors=$((errors + 1))
  elif (( count != restored[$table] )); then
    echo "Hinweis: Zeilenzahl weicht leicht ab: $table"; deviations=$((deviations + 1))
  fi
done < "$manifest"

echo "$checked Tabellen geprüft, $errors Fehler, $deviations Abweichungen."
(( checked > 0 && errors == 0 ))
