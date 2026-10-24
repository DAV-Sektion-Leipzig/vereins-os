// Datenschutzhinweise für neue Personen beim Arbeitseinsatz (R29, Art. 13 DSGVO).
// [OFFEN] Text und Link der Datenschutzhinweise der Sektion und Kennung der Version (spec.md EZ 11, plan.md O4);
// bis zur Entscheidung des Product Owners ohne Link und mit vorläufiger Kennung.

/** Link auf die Datenschutzhinweise der Sektion; null = noch nicht festgelegt. */
export const PRIVACY_NOTICE_URL: string | null = null

/** Kennung der Datenschutzhinweise, gespeichert in ez_privacy_confirmations.notice_version (1–50 Zeichen). */
export const PRIVACY_NOTICE_VERSION = 'entwurf'

/** Wortlaut des Pflicht-Häkchens (spec.md 6). */
export const PRIVACY_CONFIRM_TEXT =
  'Ich habe die Person über die Speicherung ihrer Daten informiert und auf die Datenschutzhinweise der Sektion hingewiesen.'
