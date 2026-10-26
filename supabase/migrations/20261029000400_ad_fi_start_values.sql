-- Nachtrag v0.10 (spec.md AD v0.10.0), spec T71; Übergabe FI A7; R30, R50.
-- Startwert Finanzen für die Vorlage Referent:in: FI lesen mit Reichweite „Referat“ und „darf freigeben“
-- (Bestätigung „sachlich richtig“, Product Owner 25.10.2026). Geschäftsstelle bleibt FI verwalten (ohne freigeben).
-- Überschreibt keine Änderungen des Admins (nur Zeilen, die noch „kein Zugriff“ mit Reichweite „alle“ haben).

update public.ad_template_rights r
   set level = 'read',
       scope = 'referat',
       can_approve = true
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Referent:in'
   and r.module_code = 'FI'
   and r.object is null
   and r.level = 'none'
   and r.scope = 'all'
   and not r.can_approve;
