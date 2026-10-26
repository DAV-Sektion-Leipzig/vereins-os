// PDF der Anleitung: fügt docs/anleitung/README.md und die Teile 01–04 zu einem Dokument mit Titelseite und
// Inhaltsverzeichnis zusammen. Ausgabe: docs/anleitung/dist/vereins-os-anleitung-v<Version>.pdf (nicht im Git).
// Die Version steht in docs/anleitung/README.md („Version x.y“). Für PROD erzeugt der Workflow
// .github/workflows/anleitung-pdf.yml das PDF und legt es als Release ab.
//
// Aufruf: npm run anleitung:pdf
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { pathToFileURL } from 'node:url'
import { Marked, type Tokens } from 'marked'
import { chromium } from 'playwright'

const require = createRequire(import.meta.url)
const DIR = new URL('../../docs/anleitung/', import.meta.url)
const DIST = new URL('dist/', DIR)
const LOGO = new URL('../../src/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg', import.meta.url)

// Reihenfolge im PDF; der Abschnitt für Admin und Entwicklung in README.md bleibt draußen.
const CHAPTERS = ['README.md', '01-erste-schritte.md', '02-referentinnen.md', '03-geschaeftsstelle.md', '04-admin.md']
const README_CUT = '## Anleitung aktualisieren'

/** Anker wie bei GitHub: klein, ohne Satzzeichen, Leerzeichen als Bindestrich. */
function slug(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/<[^>]+>/g, '')
    .replace(/[^\p{L}\p{N}\s-]/gu, '')
    .replace(/\s/g, '-')
}

const chapterId = (file: string) => file.replace(/\.md$/, '').toLowerCase()

function render(file: string, markdown: string): { html: string; toc: { id: string; text: string; depth: number }[] } {
  const chapter = chapterId(file)
  const toc: { id: string; text: string; depth: number }[] = []
  const marked = new Marked({
    renderer: {
      heading({ tokens, depth, text }: Tokens.Heading) {
        const id = depth === 1 ? chapter : `${chapter}--${slug(text)}`
        const inner = this.parser.parseInline(tokens)
        if (depth <= 2) toc.push({ id, text: inner.replace(/<[^>]+>/g, ''), depth })
        return `<h${depth} id="${id}">${inner}</h${depth}>\n`
      },
      link({ href, tokens }: Tokens.Link) {
        const inner = this.parser.parseInline(tokens)
        // Verweise auf andere Teile werden zu Sprüngen innerhalb des PDFs
        const m = /^([\w-]+\.md)?(?:#(.+))?$/.exec(href)
        if (m && (m[1] || m[2])) {
          const target = chapterId(m[1] ?? file)
          return `<a href="#${m[2] ? `${target}--${decodeURIComponent(m[2])}` : target}">${inner}</a>`
        }
        return `<a href="${href}">${inner}</a>`
      },
      image({ href, text }: Tokens.Image) {
        const kind = href.startsWith('diagramme/') ? 'diagramm' : href.includes('mobil') ? 'mobil' : 'bild'
        return `<figure class="${kind}"><img src="../${href}" alt="${text}"></figure>`
      },
    },
  })
  return { html: marked.parse(markdown, { async: false }), toc }
}

async function main() {
  const readme = await readFile(new URL('README.md', DIR), 'utf8')
  const version = /Version (\d+\.\d+)/.exec(readme)?.[1]
  const stand = /Stand: ([\d.]+)/.exec(readme)?.[1]
  if (!version || !stand) throw new Error('Version oder Stand fehlt in docs/anleitung/README.md.')

  const parts: string[] = []
  const toc: { id: string; text: string; depth: number }[] = []
  for (const file of CHAPTERS) {
    let markdown = await readFile(new URL(file, DIR), 'utf8')
    if (file === 'README.md') {
      markdown = markdown.split(README_CUT)[0].replace(/\n---\s*$/, '')
      // Kopfzeilen (Stand, Änderungen) stehen auf der Titelseite
      markdown = markdown.replace(/^Stand:.*\n(Änderungen.*\n)*/m, '')
    }
    // „Zurück zur Übersicht“ und ähnliche Navigationszeilen braucht das PDF nicht
    markdown = markdown.replace(/^\[Zurück zur Übersicht\].*$/m, '')
    const out = render(file, markdown)
    parts.push(`<section class="chapter">${out.html}</section>`)
    toc.push(...out.toc)
  }

  const logo = await readFile(LOGO, 'utf8')
  const fonts = [400, 500, 600]
    .map((w) => {
      const file = require.resolve(`@fontsource/fira-sans/files/fira-sans-latin-${w}-normal.woff2`)
      return `@font-face { font-family: 'Fira Sans'; font-weight: ${w}; src: url('${pathToFileURL(file)}') format('woff2'); }`
    })
    .join('\n')

  const html = `<!doctype html>
<html lang="de"><head><meta charset="utf-8"><title>Anleitung Vereins OS ${version}</title>
<style>
${fonts}
@page { size: A4; margin: 20mm 18mm 22mm; }
body { font-family: 'Fira Sans', sans-serif; color: #363b44; font-size: 10.5pt; line-height: 1.5; }
h1 { font-size: 22pt; font-weight: 600; margin: 0 0 4mm; color: #00652d; }
h2 { font-size: 15pt; font-weight: 600; margin: 8mm 0 2mm; break-after: avoid; }
h3 { font-size: 12pt; font-weight: 600; margin: 6mm 0 2mm; break-after: avoid; }
h4 { font-size: 11pt; margin: 4mm 0 1mm; }
p, ul, ol { margin: 0 0 2.5mm; }
li { margin-bottom: 1mm; }
a { color: #00652d; text-decoration: none; }
hr { border: 0; border-top: 1px solid #d6dbdf; margin: 6mm 0; }
blockquote { margin: 3mm 0; padding: 2.5mm 4mm; background: #e8f3e3; border-left: 3px solid #50ae2f; border-radius: 2mm; break-inside: avoid; }
blockquote p { margin: 0; }
table { width: 100%; border-collapse: collapse; margin: 2mm 0 4mm; font-size: 9.5pt; break-inside: avoid; }
th, td { text-align: left; vertical-align: top; padding: 1.6mm 2mm; border-bottom: 1px solid #d6dbdf; }
th { background: #f4f4f5; font-weight: 600; }
code { font-size: 9pt; background: #f4f4f5; padding: 0 1mm; border-radius: 1mm; }
figure { margin: 3mm 0 5mm; break-inside: avoid; text-align: center; }
figure img { max-width: 100%; }
figure.bild img { border: 1px solid #d6dbdf; border-radius: 2mm; max-height: 115mm; }
figure.mobil img { border: 1px solid #d6dbdf; border-radius: 3mm; max-width: 60mm; }
figure.diagramm img { max-height: 125mm; }
.keep { break-inside: avoid; }
.chapter { break-before: page; }
.cover { height: 250mm; display: flex; flex-direction: column; justify-content: space-between; }
.cover svg { width: 55mm; height: auto; }
.cover .band { height: 3mm; background: #50ae2f; margin-bottom: 30mm; }
.cover h1 { font-size: 32pt; margin-bottom: 2mm; }
.cover .sub { font-size: 14pt; color: #6e767f; }
.cover .meta { font-size: 10pt; color: #6e767f; }
.toc { break-before: page; }
.toc ul { list-style: none; padding: 0; }
.toc li.d1 { font-weight: 600; margin-top: 3mm; }
.toc li.d2 { padding-left: 6mm; }
</style></head><body>
<section class="cover">
  <div><div class="band"></div>${logo}</div>
  <div><h1>Anleitung Vereins OS</h1><div class="sub">für Referent:innen, Geschäftsstelle und Admin</div></div>
  <div class="meta">Version ${version} · Stand ${stand}<br>DAV Sektion Leipzig · Die Bilder zeigen nur erfundene Testdaten.</div>
</section>
<nav class="toc"><h1>Inhalt</h1><ul>${toc
    .map((t) => `<li class="d${t.depth}"><a href="#${t.id}">${t.depth === 1 && t.id === 'readme' ? 'Übersicht' : t.text}</a></li>`)
    .join('')}</ul></nav>
${parts.join('\n')}
</body></html>`

  await mkdir(DIST, { recursive: true })
  const htmlFile = new URL('anleitung.html', DIST)
  await writeFile(htmlFile, html)

  const browser = await chromium.launch({ executablePath: process.env.PLAYWRIGHT_CHROMIUM_PATH })
  const page = await browser.newPage()
  await page.goto(htmlFile.href, { waitUntil: 'networkidle' })
  await page.evaluate(() => document.fonts.ready)
  // Überschrift mit dem folgenden Block zusammenhalten (break-after: avoid wirkt in Chromium nicht zuverlässig)
  await page.evaluate(() => {
    // marked setzt Bilder in <p>; der Browser hinterlässt davor leere Absätze
    for (const p of document.querySelectorAll('p')) if (!p.textContent?.trim() && !p.children.length) p.remove()
    // Kleine Bilder (Dialoge) nicht auf Seitenbreite vergrößern
    for (const img of document.querySelectorAll<HTMLImageElement>('figure.bild img')) {
      if (img.naturalWidth < 1000) img.style.width = `${Math.round(img.naturalWidth * 0.7)}px`
    }
    for (const h of document.querySelectorAll('.chapter h2, .chapter h3')) {
      const next = h.nextElementSibling
      if (!next || /^H[1-3]$/.test(next.tagName)) continue
      const keep = document.createElement('div')
      keep.className = 'keep'
      h.before(keep)
      keep.append(h, next)
    }
  })
  const pdf = new URL(`vereins-os-anleitung-v${version}.pdf`, DIST)
  await page.pdf({
    path: pdf.pathname,
    format: 'A4',
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate: `<div style="font-family: sans-serif; font-size: 8px; color: #6e767f; width: 100%; padding: 0 18mm; display: flex; justify-content: space-between;">
      <span>Anleitung Vereins OS · Version ${version}</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>`,
    margin: { top: '20mm', bottom: '22mm', left: '18mm', right: '18mm' },
  })
  await browser.close()
  console.log(pdf.pathname)
}

await main()
