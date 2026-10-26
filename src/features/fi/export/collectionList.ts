// FT24 (US-FI-19, R41, 01-erhebung.md C10): Einzugsliste A4 quer aus fi_collection_export; IBAN gekürzt, Summen je
// Gruppe, je Seite und gesamt (= CtrlSum der Lastschriftdatei).
import { COLORS, createPdf, drawLogo, drawPageNumbers, type Pdf } from '@/features/fi/export/pdf'
import { formatAmount, toCents } from '@/features/fi/export/sepa'
import type { CollectionExport } from '@/features/fi/export/sepaDebit'
import { formatMoney, monthLabel } from '@/features/fi/labels'
import { formatDate, formatDateTime } from '@/lib/format'

type TableResult = { finalY: number }

const plain = (cents: number) => formatMoney(formatAmount(cents)).replace(' €', '')

export async function buildCollectionList(data: CollectionExport): Promise<Blob> {
  const { doc, autoTable } = await createPdf('landscape')
  const width = doc.internal.pageSize.getWidth()
  const height = doc.internal.pageSize.getHeight()
  const { run, creditor } = data
  const lines = [...data.lines].sort((a, b) => a.sort_no - b.sort_no)
  const totalCents = lines.reduce((s, l) => s + toCents(l.amount), 0)

  await drawLogo(doc, 28, 8)
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(14)
  doc.text(`Einzugsliste Verträge ${monthLabel(run.month)} – Lauf ${run.number}`, 14, 18)
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  doc.text(
    [creditor?.debtor_name, creditor?.creditor_id ? `Gläubiger-ID ${creditor.creditor_id}` : null, `Fälligkeit ${formatDate(run.due_date)}`]
      .filter(Boolean)
      .join(' · '),
    14,
    25,
  )
  doc.text(`Konto ${creditor?.ledger_account_collection ?? '–'}`, width - 14, 30, { align: 'right' })

  // Zeilen je Gruppe mit Zwischensumme
  type Cell = string | { content: string; colSpan?: number; styles?: Record<string, unknown> }
  const body: Cell[][] = []
  const amountRows: { index: number; cents: number }[] = []
  let currentGroup: string | null = null
  let groupCents = 0
  const flushGroup = () => {
    if (currentGroup === null) return
    body.push([
      { content: `Summe ${currentGroup}`, colSpan: 6, styles: { fontStyle: 'bold' } },
      { content: plain(groupCents), styles: { fontStyle: 'bold', halign: 'right' } },
    ])
  }
  for (const l of lines) {
    if (l.group_label !== currentGroup) {
      flushGroup()
      currentGroup = l.group_label
      groupCents = 0
    }
    const cents = toCents(l.amount)
    groupCents += cents
    amountRows.push({ index: body.length, cents })
    body.push([
      `${l.participant_last_name}, ${l.participant_preferred_name ?? l.participant_first_name}`,
      l.group_label,
      l.holder_name ?? '',
      l.mandate_reference,
      l.iban ? `•••• ${l.iban.replace(/\s+/g, '').slice(-4)}` : '–',
      l.sequence === 'FRST' ? 'Erst' : 'Folge',
      l.extra_amount
        ? `${plain(cents)}\n(davon ${plain(toCents(l.extra_amount))} ${l.extra_text ?? ''})`
        : plain(cents),
    ])
  }
  flushGroup()

  const pages = new Map<number, { cents: number; bottom: number }>()
  const amountByRow = new Map(amountRows.map((r) => [r.index, r.cents]))
  let amountRight = 0
  autoTable(doc, {
    startY: 34,
    head: [['Teilnehmer:in', 'Gruppe', 'Vertragsinhaber:in', 'Mandatsreferenz', 'IBAN', 'Art', 'Betrag (€)']],
    body,
    foot: [[{ content: `Summe Lauf ${run.number} (${lines.length} Lastschriften)`, colSpan: 6 }, plain(totalCents)]],
    showFoot: 'lastPage',
    theme: 'plain',
    margin: { left: 14, right: 14, top: 20, bottom: 24 },
    styles: { font: 'helvetica', fontSize: 9, cellPadding: 1.5, textColor: COLORS.text, lineColor: COLORS.line, lineWidth: { bottom: 0.1 } },
    headStyles: { fillColor: COLORS.head, fontStyle: 'bold' },
    footStyles: { fontStyle: 'bold', fillColor: [255, 255, 255], lineWidth: { top: 0.4 } },
    columnStyles: { 3: { cellWidth: 32 }, 4: { cellWidth: 22 }, 5: { cellWidth: 14 }, 6: { halign: 'right', cellWidth: 40 } },
    didParseCell: (cell) => {
      if (cell.column.index === 6 && cell.section !== 'body') cell.cell.styles.halign = 'right'
    },
    didDrawCell: (cell) => {
      if (cell.section !== 'body' || cell.column.index !== 6) return
      const cents = amountByRow.get(cell.row.index)
      if (cents === undefined) return
      const entry = pages.get(cell.pageNumber) ?? { cents: 0, bottom: 0 }
      entry.cents += cents
      entry.bottom = Math.max(entry.bottom, cell.cell.y + cell.cell.height)
      pages.set(cell.pageNumber, entry)
      amountRight = cell.cell.x + cell.cell.width - 1.5
    },
  })
  const table = (doc as Pdf & { lastAutoTable: TableResult }).lastAutoTable

  if (pages.size > 1) {
    // Fußzeile der Tabelle (Summe) steht auf der letzten Seite des Dokuments
    const last = doc.getNumberOfPages()
    for (const [page, entry] of pages) {
      doc.setPage(page)
      if (page === last) entry.bottom = table.finalY
      doc.setFontSize(9)
      doc.setTextColor(...COLORS.muted)
      doc.text(`Lastschriften Seite ${page}: ${plain(entry.cents)} €`, amountRight, Math.min(entry.bottom + 5, height - 16), { align: 'right' })
      doc.setTextColor(...COLORS.text)
    }
  }

  const footer = `Nachrichten-ID ${run.msg_id} · freigegeben am ${formatDateTime(run.released_at)}${
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
