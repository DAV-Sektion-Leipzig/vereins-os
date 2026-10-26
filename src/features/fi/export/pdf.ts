// Gemeinsame PDF-Bausteine (spec.md FI 6, plan.md FI): jsPDF mit jspdf-autotable, im Browser erzeugt und nur
// heruntergeladen, nie gespeichert (R21). Schrift Helvetica (Standardschrift von jsPDF, WinAnsi mit Umlauten und €);
// Logo light aus src/assets/brand, unverändert als Bild (marke.md 1–3).
import type { jsPDF } from 'jspdf'
import logoUrl from '@/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg?url'

export type Pdf = jsPDF

/** Felsgrau (marke.md: Handout #707680) für Linien und Nebentexte; Text dunkel. */
export const COLORS = {
  text: [33, 37, 41] as [number, number, number],
  muted: [112, 118, 128] as [number, number, number],
  line: [165, 174, 184] as [number, number, number],
  head: [238, 240, 242] as [number, number, number],
}

export async function createPdf(orientation: 'portrait' | 'landscape'): Promise<{ doc: Pdf; autoTable: typeof import('jspdf-autotable').default }> {
  const [{ jsPDF }, autoTable] = await Promise.all([import('jspdf'), import('jspdf-autotable')])
  const doc = new jsPDF({ orientation, unit: 'mm', format: 'a4' })
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(...COLORS.text)
  return { doc, autoTable: autoTable.default }
}

let logoCache: Promise<{ data: string; ratio: number } | null> | null = null

/** Logo als PNG (SVG → Canvas); ohne Logo weiter, wenn das Bild nicht lädt. */
export function loadLogo(): Promise<{ data: string; ratio: number } | null> {
  logoCache ??= new Promise((resolve) => {
    if (typeof Image === 'undefined') return resolve(null)
    const img = new Image()
    img.onload = () => {
      try {
        const width = 600
        const ratio = img.naturalHeight / img.naturalWidth || 0.5
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = Math.round(width * ratio)
        const ctx = canvas.getContext('2d')
        if (!ctx) return resolve(null)
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
        resolve({ data: canvas.toDataURL('image/png'), ratio })
      } catch {
        resolve(null)
      }
    }
    img.onerror = () => resolve(null)
    img.src = logoUrl
  })
  return logoCache
}

/** Logo oben rechts mit der Breite width (mm). */
export async function drawLogo(doc: Pdf, width = 32, top = 10) {
  const logo = await loadLogo()
  if (!logo) return
  const pageWidth = doc.internal.pageSize.getWidth()
  doc.addImage(logo.data, 'PNG', pageWidth - 14 - width, top, width, width * logo.ratio)
}

/** Seitenzahl „Seite x von y“ unten rechts auf allen Seiten. */
export function drawPageNumbers(doc: Pdf, prefix = '') {
  const pages = doc.getNumberOfPages()
  const width = doc.internal.pageSize.getWidth()
  const height = doc.internal.pageSize.getHeight()
  for (let i = 1; i <= pages; i++) {
    doc.setPage(i)
    doc.setFontSize(8)
    doc.setTextColor(...COLORS.muted)
    doc.text(`${prefix}Seite ${i} von ${pages}`, width - 14, height - 8, { align: 'right' })
  }
  doc.setTextColor(...COLORS.text)
}

/** Dateiname ohne Umlaute und Sonderzeichen (spec.md FI 6). */
export function fileSafe(text: string): string {
  return text
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue')
    .replace(/Ä/g, 'Ae').replace(/Ö/g, 'Oe').replace(/Ü/g, 'Ue').replace(/ß/g, 'ss')
    .normalize('NFKD').replace(/[̀-ͯ]/g, '')
    .replace(/[^A-Za-z0-9-]+/g, '_').replace(/^_+|_+$/g, '')
}

/** Datei im Browser herunterladen (nichts wird gespeichert, R21). */
export function downloadBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = fileName
  document.body.appendChild(a)
  a.click()
  a.remove()
  window.setTimeout(() => URL.revokeObjectURL(url), 10_000)
}
