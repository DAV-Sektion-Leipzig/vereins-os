// FT13 (US-FI-11, R18): Abrechnungsdokument je Person als PDF (A4 hoch, eine Person je Seite) aus fi_settlement_document;
// mehrere Abrechnungen in einer Datei. Wird nur heruntergeladen, nie gespeichert (R21).
import { fiRpc } from '@/features/fi/rpc'
import { formatMoney, formatQuantity, POSITION_LABELS, RATE_ROLE_LABELS, type Half, type Position, type RateRole } from '@/features/fi/labels'
import { COLORS, createPdf, downloadBlob, drawLogo, drawPageNumbers, fileSafe, type Pdf } from '@/features/fi/export/pdf'
import { formatDate, personName } from '@/lib/format'
import { supabase } from '@/lib/supabase'

/** Erklärung der Person zum Freibetrag (R18; Wortlaut [ANNAHME], Prüfung durch den Product Owner bei der Abnahme). */
export const DECLARATION =
  'Ich versichere, dass die Angaben richtig sind und die Vergütung zusammen mit anderen Einnahmen aus nebenberuflicher ' +
  'Tätigkeit nach § 3 Nr. 26 EStG den Freibetrag im Kalenderjahr nicht übersteigt. Änderungen teile ich der Sektion ' +
  'unverzüglich mit.'

export type DocumentItem = {
  event_date: string
  event_label: string | null
  position: Position
  rate_role: RateRole
  quantity: number
  rate: number | null
  amount: number | null
  correction_reason: string | null
  exception_reason: string | null
}

export type SettlementDocument = {
  id: string
  first_name: string
  last_name: string
  preferred_name: string | null
  year: number
  half: 1 | 2
  amount: number
  deadline: string | null
  groups: { label: string; total: number; items: DocumentItem[] }[] | null
}

async function sectionName(): Promise<string | null> {
  const { data } = await supabase.rpc('ad_payout_settings_at', { p_date: new Date().toISOString().slice(0, 10) })
  return Array.isArray(data) && data[0] ? (data[0] as { debtor_name: string }).debtor_name : null
}

async function drawDocument(doc: Pdf, autoTable: Awaited<ReturnType<typeof createPdf>>['autoTable'], s: SettlementDocument, section: string | null) {
  const width = doc.internal.pageSize.getWidth()
  await drawLogo(doc, 30, 10)
  doc.setFontSize(9)
  doc.setTextColor(...COLORS.muted)
  if (section) doc.text(section, 14, 14)
  doc.setTextColor(...COLORS.text)
  doc.setFontSize(15)
  doc.setFont('helvetica', 'bold')
  doc.text(`Abrechnung Übungsleitervergütung ${s.half}. Halbjahr ${s.year}`, 14, 30)
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(11)
  doc.text(personName(s), 14, 38)

  let y = 46
  for (const group of s.groups ?? []) {
    const body: (string | { content: string; colSpan?: number; styles?: Record<string, unknown> })[][] = []
    for (const i of group.items) {
      body.push([
        formatDate(i.event_date),
        i.event_label ?? '',
        POSITION_LABELS[i.position] ?? i.position,
        RATE_ROLE_LABELS[i.rate_role] ?? i.rate_role,
        formatQuantity(i.quantity),
        formatMoney(i.rate),
        formatMoney(i.amount),
      ])
      const notes = [
        i.correction_reason ? `Korrektur: ${i.correction_reason}` : null,
        i.exception_reason ? `Ausnahme: ${i.exception_reason}` : null,
      ].filter(Boolean)
      if (notes.length > 0) {
        body.push([{ content: notes.join(' · '), colSpan: 7, styles: { fontSize: 8, textColor: COLORS.muted, cellPadding: { top: 0, bottom: 1.5, left: 2, right: 2 } } }])
      }
    }
    body.push([
      { content: `Summe ${group.label}`, colSpan: 6, styles: { fontStyle: 'bold' } },
      { content: formatMoney(group.total), styles: { fontStyle: 'bold', halign: 'right' } },
    ])
    autoTable(doc, {
      startY: y,
      head: [[{ content: group.label, colSpan: 7, styles: { fontStyle: 'bold', fillColor: [255, 255, 255], textColor: COLORS.text, fontSize: 10 } }],
        ['Datum', 'Einsatz', 'Position', 'Satzart', 'Menge', 'Satz', 'Betrag']],
      body,
      theme: 'plain',
      margin: { left: 14, right: 14 },
      styles: { font: 'helvetica', fontSize: 9, cellPadding: 1.5, textColor: COLORS.text, lineColor: COLORS.line },
      headStyles: { fillColor: COLORS.head, fontStyle: 'bold' },
      columnStyles: { 0: { cellWidth: 22 }, 4: { halign: 'right', cellWidth: 14 }, 5: { halign: 'right', cellWidth: 22 }, 6: { halign: 'right', cellWidth: 24 } },
      didParseCell: (data) => {
        if (data.section === 'head' && data.row.index === 1 && data.column.index >= 4) data.cell.styles.halign = 'right'
      },
    })
    y = (doc as Pdf & { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 6
  }

  // Gesamt, Frist, Erklärung und Unterschrift; bei wenig Platz auf neuer Seite
  if (y > 225) {
    doc.addPage()
    y = 20
  }
  doc.setDrawColor(...COLORS.line)
  doc.line(14, y, width - 14, y)
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(11)
  doc.text('Gesamt', 14, y + 6)
  doc.text(formatMoney(s.amount), width - 14, y + 6, { align: 'right' })
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(9)
  y += 14
  const deadline = s.deadline ? formatDate(s.deadline) : '–'
  const lines = [
    `Bitte unterschrieben bis ${deadline} in der Geschäftsstelle abgeben. Nach Ablauf der Frist erlischt der Anspruch.`,
    '',
    DECLARATION,
  ]
  for (const text of lines) {
    const wrapped = doc.splitTextToSize(text, width - 28) as string[]
    doc.text(wrapped, 14, y)
    y += wrapped.length * 4.2 + (text ? 1 : 0)
  }
  y += 16
  doc.setDrawColor(...COLORS.text)
  doc.line(14, y, 84, y)
  doc.line(100, y, width - 14, y)
  doc.setFontSize(8)
  doc.setTextColor(...COLORS.muted)
  doc.text('Ort, Datum', 14, y + 4)
  doc.text('Unterschrift', 100, y + 4)
  doc.setTextColor(...COLORS.text)
}

/** PDF mit einer Person je Seite (bei langen Abrechnungen Folgeseiten). */
export async function buildSettlementDocuments(docs: SettlementDocument[], section: string | null): Promise<Blob> {
  const { doc, autoTable } = await createPdf('portrait')
  for (let i = 0; i < docs.length; i++) {
    if (i > 0) doc.addPage()
    await drawDocument(doc, autoTable, docs[i], section)
  }
  drawPageNumbers(doc)
  return doc.output('blob')
}

/**
 * Lädt die Daten (nur abgeschlossene oder spätere Abrechnungen, FI verwalten) und lädt das PDF herunter.
 * Gibt eine Fehlermeldung zurück oder null.
 */
export async function downloadSettlementDocuments(ids: string[], half: Half, names: Record<string, string> = {}): Promise<string | null> {
  if (ids.length === 0) return null
  const res = await fiRpc<SettlementDocument[]>('fi_settlement_document', { p_ids: ids }, names)
  if (res.error) return res.error.text
  const docs = res.data
  try {
    const blob = await buildSettlementDocuments(docs, await sectionName())
    const fileName =
      docs.length === 1
        ? `Abrechnung_UEL_${half.year}_${half.half}_${fileSafe(personName(docs[0]))}.pdf`
        : `Abrechnungen_UEL_${half.year}_${half.half}.pdf`
    downloadBlob(blob, fileName)
    return null
  } catch {
    return 'Das PDF konnte nicht erzeugt werden. Bitte erneut versuchen.'
  }
}
