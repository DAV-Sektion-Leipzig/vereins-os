// FT14 (US-FI-15, R27, R28, 01-erhebung.md C6): Auszahlliste A4 quer aus fi_payout_export, ohne IBAN;
// Zwischensumme je Seite, Summe der Runde (= CtrlSum der Überweisungsdatei), „sachl. richtig“ aus den Bestätigungen.
import { COLORS, createPdf, drawLogo, drawPageNumbers, type Pdf } from '@/features/fi/export/pdf'
import { formatAmount, toCents, type PayoutExport } from '@/features/fi/export/sepa'
import { formatMoney } from '@/features/fi/labels'
import { formatDate, formatDateTime } from '@/lib/format'

type TableResult = { finalY: number }

export async function buildPayoutList(data: PayoutExport): Promise<Blob> {
  const { doc, autoTable } = await createPdf('landscape')
  const width = doc.internal.pageSize.getWidth()
  const height = doc.internal.pageSize.getHeight()
  const { run } = data
  const lines = [...data.lines].sort((a, b) => a.sort_no - b.sort_no)
  const totalCents = lines.reduce((s, l) => s + toCents(l.amount), 0)
  // Zwischensumme je Seite: Beträge und untere Kante der letzten Zeile je Seite, rechte Kante der Betragsspalte
  const pages = new Map<number, { cents: number; bottom: number }>()
  let amountRight = 0

  await drawLogo(doc, 28, 8)
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(14)
  doc.text(`Auszahlliste Übungsleitervergütung ${run.half}. Hj. ${run.year} – Runde ${run.number}`, 14, 18)
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  if (data.debtor) doc.text(data.debtor.debtor_name, 14, 25)
  doc.text(`Konto ${data.debtor?.ledger_account ?? '–'}`, width - 14, 30, { align: 'right' })

  autoTable(doc, {
    startY: 34,
    head: [['Zuname', 'Vorname', 'Auszahlungsbetrag (€)', 'Gruppe']],
    body: lines.map((l) => [l.last_name, l.first_name, formatMoney(l.amount).replace(' €', ''), l.group_label]),
    foot: [['Summe der Runde', `${lines.length} Überweisungen`, formatMoney(formatAmount(totalCents)).replace(' €', ''), '']],
    showFoot: 'lastPage',
    theme: 'plain',
    margin: { left: 14, right: 14, top: 20, bottom: 24 },
    styles: { font: 'helvetica', fontSize: 9.5, cellPadding: 1.6, textColor: COLORS.text, lineColor: COLORS.line, lineWidth: { bottom: 0.1 } },
    headStyles: { fillColor: COLORS.head, fontStyle: 'bold' },
    footStyles: { fontStyle: 'bold', fillColor: [255, 255, 255], lineWidth: { top: 0.4 } },
    columnStyles: { 0: { cellWidth: 70 }, 1: { cellWidth: 60 }, 2: { halign: 'right', cellWidth: 48 } },
    didParseCell: (cell) => {
      if (cell.column.index === 2 && cell.section !== 'body') cell.cell.styles.halign = 'right'
    },
    didDrawCell: (cell) => {
      if (cell.section !== 'body' || cell.column.index !== 2) return
      const entry = pages.get(cell.pageNumber) ?? { cents: 0, bottom: 0 }
      entry.cents += toCents(lines[cell.row.index].amount)
      entry.bottom = Math.max(entry.bottom, cell.cell.y + cell.cell.height)
      pages.set(cell.pageNumber, entry)
      amountRight = cell.cell.x + cell.cell.width - 1.6
    },
  })
  const table = (doc as Pdf & { lastAutoTable: TableResult }).lastAutoTable

  // Zwischensumme je Seite unter der letzten Zeile der Seite (nur bei mehreren Seiten)
  if (pages.size > 1) {
    // Fußzeile der Tabelle (Summe) steht auf der letzten Seite des Dokuments
    const last = doc.getNumberOfPages()
    for (const [page, entry] of pages) {
      doc.setPage(page)
      // letzte Seite: unter der Summe der Runde
      if (page === last) entry.bottom = table.finalY
      doc.setFontSize(9)
      doc.setTextColor(...COLORS.muted)
      doc.text(`Zwischensumme Seite ${page}: ${formatMoney(formatAmount(entry.cents))}`, amountRight, Math.min(entry.bottom + 5, height - 16), { align: 'right' })
      doc.setTextColor(...COLORS.text)
    }
    doc.setPage(doc.getNumberOfPages())
  }

  // Unterschriften: „sachl. richtig“ aus den Bestätigungen, „gf Vorstand“ und „angewiesen“ leer (C6)
  let y = table.finalY + (pages.size > 1 ? 16 : 12)
  const needed = Math.max(28, 12 + data.confirmations.length * 4.5 + 10)
  if (y + needed > height - 18) {
    doc.addPage()
    y = 20
  }
  const colWidth = (width - 28 - 16) / 3
  const cols = [14, 14 + colWidth + 8, 14 + 2 * (colWidth + 8)]
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(10)
  doc.text('sachl. richtig', cols[0], y)
  doc.text('gf Vorstand', cols[1], y)
  doc.text('angewiesen', cols[2], y)
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(9)
  let cy = y + 6
  for (const c of data.confirmations) {
    const text = `${c.referat_name}: ${c.name ?? 'unbekannt'}, ${formatDate(c.date)}${c.is_substitute ? ' (in Vertretung, Geschäftsstelle)' : ''}`
    const wrapped = doc.splitTextToSize(text, colWidth) as string[]
    doc.text(wrapped, cols[0], cy)
    cy += wrapped.length * 4.5
  }
  if (data.confirmations.length > 0) {
    doc.setFontSize(7.5)
    doc.setTextColor(...COLORS.muted)
    doc.text('bestätigt im Vereins OS', cols[0], cy + 1)
    doc.setTextColor(...COLORS.text)
  }
  const signY = Math.max(cy + 8, y + 20)
  doc.setDrawColor(...COLORS.text)
  doc.line(cols[1], signY, cols[1] + colWidth, signY)
  doc.line(cols[2], signY, cols[2] + colWidth, signY)
  doc.setFontSize(7.5)
  doc.setTextColor(...COLORS.muted)
  doc.text('Datum, Unterschrift', cols[1], signY + 4)
  doc.text('Datum, Unterschrift', cols[2], signY + 4)

  // Fuß auf jeder Seite: Ausführungsdatum, Nachrichten-ID, Freigabe
  const footer = `Ausführungsdatum ${formatDate(run.execution_date)} · Nachrichten-ID ${run.msg_id} · freigegeben am ${formatDateTime(run.released_at)}${
    run.released_by_name ? ` von ${run.released_by_name}` : ''
  }`
  for (let i = 1; i <= doc.getNumberOfPages(); i++) {
    doc.setPage(i)
    doc.setFontSize(8)
    doc.setTextColor(...COLORS.muted)
    doc.text(footer, 14, height - 8)
  }
  doc.setTextColor(...COLORS.text)
  drawPageNumbers(doc)
  return doc.output('blob')
}
