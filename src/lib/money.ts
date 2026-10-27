// Betragseingaben in Euro aus Freitextfeldern lesen (Code-Review W-02). Punkt und Komma gelten gleichwertig als
// Dezimaltrenner, damit „12.50“ (iOS- oder englische Tastatur) nicht zu 1.250 € wird. Tausendertrenner werden
// abgelehnt, weil „1.250“ sonst mehrdeutig wäre. Nicht für Dateiimporte (DATEV-Export „1.234,56“, siehe
// src/features/ds/budget/parse/csv.ts). Ohne Abhängigkeiten, damit die Tests unter scripts/money mit tsx laufen.

/** Meldung für Betragsfelder ohne eigene Modulmeldung. */
export const EURO_INPUT_HINT = 'Bitte einen Betrag wie 12,50 eingeben (ohne Tausenderpunkt).'

const EURO_PATTERN = /^-?\d{1,7}([.,]\d{1,2})?$/

/**
 * Betrag aus einer Eingabe wie „12,50“, „12.50“ oder „7 €“ → Zahl; leer oder ungültig → null.
 * Höchstens sieben Vorkomma- und zwei Nachkommastellen, kein Tausendertrenner. Ein Minus nur mit `allowNegative`.
 */
export function parseEuro(text: string, options: { allowNegative?: boolean } = {}): number | null {
  const compact = text.replace(/\s/g, '').replace(/€/g, '')
  if (!EURO_PATTERN.test(compact)) return null
  if (compact.startsWith('-') && !options.allowNegative) return null
  const value = Number(compact.replace(',', '.'))
  if (!Number.isFinite(value)) return null
  return Object.is(value, -0) ? 0 : value
}
