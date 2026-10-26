// T023 (US-TK-21; spec.md TK 6, R14): Planung als PDF nach Prototyp 7.5 – A4, Kopfzeile, Statuskasten, Leitung und
// Kontakt, Yolawo-Eingabeblatt, Kalkulation, CO2-Bilanz, Intern, Ausschreibungstext; Fußzeile „Tourenkonzept · Titel“
// und „Seite x von y“. Im Browser erzeugt (jsPDF, gebündelt), nur heruntergeladen, keine eingebetteten Daten (R14).
// Kontakt- und Notfalldaten nur, wenn sie im TextInput stehen (Recht tk_can_read_contacts).
import { descText, summaryText, termText, yolawoFields, type TextInput } from '@/features/tk/ausgaben/texts'
import { COLORS, createPdf, downloadBlob, drawLogo, type Pdf } from '@/features/fi/export/pdf'
import { FITNESS_LABELS, PLAN_TYPE_LABELS, ROLE_LABELS } from '@/features/tk/labels'

const MARGIN = 18

/** Dateiname Tourenkonzept_{Beginn | ohne-Datum}_{Titel}.pdf (Prototyp 7.5; höchstens 60 Zeichen Titel). */
export function pdfFileName(start: string | null, title: string): string {
  const slug = title
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue').replace(/Ä/g, 'Ae').replace(/Ö/g, 'Oe').replace(/Ü/g, 'Ue')
    .replace(/ß/g, 'ss')
    .replace(/[^A-Za-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60)
  return `Tourenkonzept_${start ?? 'ohne-Datum'}_${slug || 'ohne-Titel'}.pdf`
}

/** Zeichen außerhalb von WinAnsi (Helvetica) ersetzen, z. B. Pfeile und CO₂. */
function safe(text: string): string {
  return text.replace(/↑/g, 'auf').replace(/↓/g, 'ab').replace(/→/g, '->').replace(/–/g, '-').replace(/[‐-―]/g, '-')
    .replace(/≤/g, '<=')
    .split('')
    .filter((ch) => {
      const c = ch.charCodeAt(0)
      return c === 9 || c === 10 || c === 13 || (c >= 32 && c <= 126) || (c >= 160 && c <= 255) || '€„“‚‘’…•'.includes(ch)
    })
    .join('')
}

type State = { doc: Pdf; y: number; width: number; height: number }

function ensure(s: State, needed: number) {
  if (s.y + needed > s.height - 16) {
    s.doc.addPage()
    s.y = MARGIN
  }
}

function heading(s: State, text: string) {
  ensure(s, 14)
  s.y += 4
  s.doc.setFont('helvetica', 'bold')
  s.doc.setFontSize(12)
  s.doc.text(safe(text), MARGIN, s.y)
  s.doc.setFont('helvetica', 'normal')
  s.y += 6
}

function paragraph(s: State, text: string, opts: { bold?: boolean; size?: number } = {}) {
  s.doc.setFont('helvetica', opts.bold ? 'bold' : 'normal')
  s.doc.setFontSize(opts.size ?? 9.5)
  const wrapped = s.doc.splitTextToSize(safe(text), s.width - 2 * MARGIN) as string[]
  for (const line of wrapped) {
    ensure(s, 5)
    s.doc.text(line, MARGIN, s.y)
    s.y += 4.4
  }
  s.doc.setFont('helvetica', 'normal')
}

/** Abschnitt aus der Zusammenfassung (Überschrift in Großbuchstaben) als Textblock. */
function summaryBlock(summary: string, title: string): string {
  const block = summary.split('\n\n').find((b) => b.startsWith(title))
  return block ? block.split('\n').slice(1).join('\n') : ''
}

export async function buildPlanPdf(t: TextInput, missingLabels: string[], leaderNames: string): Promise<Blob> {
  const { doc, autoTable } = await createPdf('portrait')
  const width = doc.internal.pageSize.getWidth()
  const height = doc.internal.pageSize.getHeight()
  const f = t.fields
  const s: State = { doc, y: MARGIN, width, height }
  doc.setProperties({
    title: safe(`Tourenkonzept: ${f.title}`),
    subject: 'Tourenkonzept DAV Sektion Leipzig',
    author: safe(leaderNames),
    creator: 'Vereins OS, Planungshilfe Touren und Kurse',
  })

  // 1. Kopf
  await drawLogo(doc, 30, 10)
  doc.setFontSize(8)
  doc.setTextColor(...COLORS.muted)
  doc.text('DAV SEKTION LEIPZIG · TOURENKONZEPT', MARGIN, 14)
  doc.setTextColor(...COLORS.text)
  s.y = 30
  paragraph(s, f.title || '(ohne Titel)', { bold: true, size: 15 })
  s.y += 1
  paragraph(s, [termText(f), PLAN_TYPE_LABELS[f.plan_type], f.sport, f.region].filter(Boolean).join(' · '))

  // 2. Statuskasten
  s.y += 2
  const status = missingLabels.length ? `Noch unvollständig. Es fehlen: ${missingLabels.join(', ')}` : 'Vollständig ausgefüllt.'
  doc.setFontSize(9.5)
  const statusLines = doc.splitTextToSize(safe(status), width - 2 * MARGIN - 6) as string[]
  const boxHeight = statusLines.length * 4.4 + 4
  ensure(s, boxHeight + 2)
  doc.setFillColor(...((missingLabels.length ? [255, 243, 205] : [220, 242, 225]) as [number, number, number]))
  doc.rect(MARGIN, s.y - 1, width - 2 * MARGIN, boxHeight, 'F')
  doc.text(statusLines, MARGIN + 3, s.y + 3.5)
  s.y += boxHeight + 3

  // 3. Erstellt am, Yolawo-Eingabe
  paragraph(s, summaryText(t, missingLabels).split('\n').slice(1, 3).join(' · '))

  const tableStyles = {
    theme: 'plain' as const,
    margin: { left: MARGIN, right: MARGIN },
    styles: { font: 'helvetica', fontSize: 8.5, cellPadding: 1.4, textColor: COLORS.text, lineColor: COLORS.line, lineWidth: 0.1 },
    headStyles: { fillColor: COLORS.head, fontStyle: 'bold' as const },
  }
  const after = () => {
    s.y = (doc as Pdf & { lastAutoTable: { finalY: number } }).lastAutoTable.finalY + 4
  }

  // 4. Leitung und Kontakt
  heading(s, 'Leitung und Kontakt')
  autoTable(doc, {
    ...tableStyles,
    startY: s.y,
    head: [['Rolle', 'Name', 'Lizenz', 'Satzart']],
    body: t.leaders.map((l) => [ROLE_LABELS[l.role], safe(l.name), safe(l.license_name ?? '–'), l.rate_kind === 'trainer' ? 'Trainersatz' : 'Helfersatz']),
  })
  after()
  if (t.contacts !== undefined) {
    const contact = summaryBlock(summaryText(t, missingLabels), 'LEITUNG').split('\n').filter((l) => !l.startsWith('- ')).join('\n')
    if (contact) paragraph(s, contact)
  }

  // 5. Yolawo-Eingabeblatt
  heading(s, 'Yolawo-Eingabeblatt')
  autoTable(doc, {
    ...tableStyles,
    startY: s.y,
    head: [['Gruppe', 'Feld', 'Inhalt']],
    body: yolawoFields(t).map((y) => [safe(y.group), safe(y.field), safe(y.field === 'Beschreibung' ? 'siehe Ausschreibungstext am Ende' : (y.value ?? 'fehlt'))]),
    columnStyles: { 0: { cellWidth: 32 }, 1: { cellWidth: 38 } },
  })
  after()

  // 6.–8. Kalkulation, CO2-Bilanz, Intern (wie die Zusammenfassung, Prototyp 7.3)
  const summary = summaryText(t, missingLabels)
  heading(s, 'Kalkulation')
  paragraph(s, summaryBlock(summary, 'KALKULATION'))
  heading(s, 'CO2-Bilanz (Planung)')
  paragraph(s, summaryBlock(summary, 'CO2-BILANZ'))
  heading(s, 'Intern')
  paragraph(s, summaryBlock(summary, 'INTERN'))
  if (f.fitness) paragraph(s, `Kondition: ${FITNESS_LABELS[f.fitness]}`)

  // 9. Ausschreibungstext: Überschrift = kurze Zeile ohne Satzzeichen am Ende nach einer Leerzeile
  heading(s, 'Ausschreibungstext')
  for (const block of descText(t).split('\n\n')) {
    const [first, ...rest] = block.split('\n')
    const isHeading = first.length < 45 && !/[:.!?]$/.test(first) && !first.includes(': ') && rest.length > 0
    if (isHeading) {
      s.y += 1
      paragraph(s, first, { bold: true, size: 11 })
      paragraph(s, rest.join('\n'))
    } else {
      paragraph(s, block)
    }
    s.y += 2
  }

  // Fußzeile
  const pages = doc.getNumberOfPages()
  for (let i = 1; i <= pages; i++) {
    doc.setPage(i)
    doc.setFontSize(8)
    doc.setTextColor(...COLORS.muted)
    doc.text(safe(`Tourenkonzept · ${f.title}`).slice(0, 90), MARGIN, height - 8)
    doc.text(`Seite ${i} von ${pages}`, width - MARGIN, height - 8, { align: 'right' })
  }
  doc.setTextColor(...COLORS.text)
  return doc.output('blob')
}

/** Erzeugt und lädt das PDF herunter; gibt eine Fehlermeldung zurück oder null (US-TK-21 AK4). */
export async function downloadPlanPdf(t: TextInput, missingLabels: string[]): Promise<string | null> {
  try {
    const leaderNames = t.leaders.map((l) => l.name).join(', ')
    const blob = await buildPlanPdf(t, missingLabels, leaderNames)
    downloadBlob(blob, pdfFileName(t.fields.start_date, t.fields.title))
    return null
  } catch {
    return 'PDF konnte nicht gespeichert werden.'
  }
}
