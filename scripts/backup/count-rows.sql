-- Zeilenzahl je Tabelle in public und von auth.users (Spalten: Tabelle, Anzahl).
-- Grundlage für den Vergleich nach der Wiederherstellung (dump.sh schreibt manifest.tsv, verify.sh vergleicht).
select format('%I.%I', table_schema, table_name),
       (xpath('/row/c/text()',
              query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text
from information_schema.tables
where table_type = 'BASE TABLE'
  and (table_schema = 'public' or (table_schema = 'auth' and table_name = 'users'))
order by 1;
