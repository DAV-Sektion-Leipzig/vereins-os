// Gemeinsame Hilfen zum Lesen der Dateien im Browser (spec.md DS v0.2 Abschnitt 1, plan.md P6). Ohne Abhängigkeiten,
// damit die Unit-Tests unter scripts/ds-budget mit tsx laufen.

/** Datei als Text: UTF-8 (mit oder ohne BOM), sonst Windows-1252 (prototyp-budget-dashboard.md Abschnitt 3). */
export function decodeText(bytes: ArrayBuffer | Uint8Array): string {
  const data = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes)
  try {
    return new TextDecoder('utf-8', { fatal: true }).decode(data).replace(/^﻿/, '')
  } catch {
    return new TextDecoder('windows-1252').decode(data)
  }
}

/** CSV mit Trennzeichen (Standard `;`), Anführungszeichen und `""` als Escape; Zeilenenden CRLF oder LF. */
export function parseCsv(text: string, delimiter = ';'): string[][] {
  const rows: string[][] = []
  let row: string[] = []
  let cell = ''
  let quoted = false
  for (let i = 0; i < text.length; i++) {
    const c = text[i]
    if (quoted) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          cell += '"'
          i++
        } else {
          quoted = false
        }
      } else {
        cell += c
      }
    } else if (c === '"' && cell === '') {
      quoted = true
    } else if (c === delimiter) {
      row.push(cell)
      cell = ''
    } else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++
      row.push(cell)
      rows.push(row)
      row = []
      cell = ''
    } else {
      cell += c
    }
  }
  if (cell !== '' || row.length > 0) {
    row.push(cell)
    rows.push(row)
  }
  return rows
}

/** Vergleichsform für Spaltennamen: klein, ohne Leerraum am Rand, mehrfacher Leerraum zusammengefasst. */
export function headerKey(value: unknown): string {
  return String(value ?? '')
    .trim()
    .replace(/\s+/g, ' ')
    .toLowerCase()
}

/** Betrag „1.234,56“ (auch „-1.234,56“, „1234,5“ oder Zahl) → Zahl; leer → null; unlesbar → NaN. */
export function parseAmount(value: unknown): number | null {
  if (typeof value === 'number') return Number.isFinite(value) ? value : Number.NaN
  const text = String(value ?? '').trim()
  if (text === '') return null
  const normalized = text.replace(/\s/g, '').replace(/€/g, '').replace(/\./g, '').replace(',', '.')
  if (!/^-?\d+(\.\d+)?$/.test(normalized)) return Number.NaN
  return Number(normalized)
}

/** Datum „TT.MM.JJJJ“ (auch „T.M.JJ“ oder ISO) → „JJJJ-MM-TT“; sonst null. */
export function parseGermanDate(value: unknown): string | null {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString().slice(0, 10)
  }
  const text = String(value ?? '').trim()
  const iso = /^(\d{4})-(\d{2})-(\d{2})/.exec(text)
  if (iso) return `${iso[1]}-${iso[2]}-${iso[3]}`
  const m = /^(\d{1,2})\.(\d{1,2})\.(\d{2}|\d{4})$/.exec(text)
  if (!m) return null
  const year = m[3].length === 2 ? 2000 + Number(m[3]) : Number(m[3])
  const month = Number(m[2])
  const day = Number(m[1])
  const date = new Date(Date.UTC(year, month - 1, day))
  if (date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
}
