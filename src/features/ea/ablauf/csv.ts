// CSV-Export der Stichtagsliste (US-EA-12 AK3; T048): UTF-8 mit BOM, Semikolon, ohne Kontaktdaten.
import type { ExpiryListRow } from '@/features/ea/ablauf/data'
import { formatDate } from '@/lib/format'

const HEADER = ['Nachname', 'Vorname', 'Rufname', 'Referate', 'Kürzel', 'Bezeichnung', 'gültig bis']

/** Werte mit Semikolon, Anführungszeichen oder Zeilenumbruch in Anführungszeichen; innere verdoppelt. */
export function csvValue(value: string): string {
  return /[;"\r\n]/.test(value) ? `"${value.replace(/"/g, '""')}"` : value
}

export function toCsv(rows: ExpiryListRow[]): string {
  const lines = [
    HEADER,
    ...rows.map((r) => [
      r.lastName,
      r.firstName,
      r.preferredName ?? '',
      r.referate.join(', '),
      r.code ?? '',
      r.qualificationName,
      formatDate(r.validUntil),
    ]),
  ]
  // BOM, damit Excel die Datei als UTF-8 liest (Umlaute)
  return '﻿' + lines.map((cells) => cells.map(csvValue).join(';')).join('\r\n') + '\r\n'
}

export function downloadCsv(rows: ExpiryListRow[], year: number) {
  const url = URL.createObjectURL(new Blob([toCsv(rows)], { type: 'text/csv;charset=utf-8' }))
  const link = document.createElement('a')
  link.href = url
  link.download = `ablauf-${year}.csv`
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}
