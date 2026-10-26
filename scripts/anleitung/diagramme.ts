// Ablaufdiagramme der Anleitung: rendert docs/anleitung/diagramme/*.mmd (Mermaid) als PNG in DAV-Farben.
// Die PNG-Dateien werden mit eingecheckt, damit GitHub und das PDF sie ohne weiteres Werkzeug zeigen.
//
// Aufruf: npm run anleitung:diagramme            alle Diagramme
//         npm run anleitung:diagramme -- einsatz  nur Diagramme, deren Name den Text enthält
import { readdir, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { chromium } from 'playwright'

const require = createRequire(import.meta.url)
const DIR = new URL('../../docs/anleitung/diagramme/', import.meta.url)

// Farben nach src/index.css und docs/marke.md
const THEME = {
  fontFamily: 'Fira Sans, sans-serif',
  fontSize: '15px',
  primaryColor: '#e8f3e3',
  primaryBorderColor: '#00652d',
  primaryTextColor: '#363b44',
  lineColor: '#6e767f',
  secondaryColor: '#f4f4f5',
  tertiaryColor: '#ffffff',
  edgeLabelBackground: '#ffffff',
}

// Schrift als data-URL, weil die Seite keine Dateien nachladen darf
async function fontFace(weight: number): Promise<string> {
  const file = require.resolve(`@fontsource/fira-sans/files/fira-sans-latin-${weight}-normal.woff2`)
  const data = (await readFile(file)).toString('base64')
  return `@font-face { font-family: 'Fira Sans'; font-weight: ${weight}; src: url(data:font/woff2;base64,${data}) format('woff2'); }`
}

async function main() {
  const filter = process.argv.slice(2)
  const files = (await readdir(DIR))
    .filter((f) => f.endsWith('.mmd'))
    .filter((f) => !filter.length || filter.some((x) => f.includes(x)))

  const browser = await chromium.launch({ executablePath: process.env.PLAYWRIGHT_CHROMIUM_PATH })
  const page = await browser.newPage({ deviceScaleFactor: 2, viewport: { width: 1400, height: 900 } })
  await page.setContent(
    `<!doctype html><html><head><style>${(await Promise.all([400, 500, 600].map(fontFace))).join('\n')}
      body { margin: 0; background: #fff; font-family: 'Fira Sans', sans-serif; }
      #out { display: inline-block; padding: 16px; }
      small { font-size: 13px; color: #555b63; }</style></head><body><div id="out"></div></body></html>`,
  )
  await page.addScriptTag({ path: require.resolve('mermaid/dist/mermaid.min.js') })
  await page.evaluate(() => document.fonts.load("15px 'Fira Sans'"))

  for (const file of files) {
    const source = await readFile(new URL(file, DIR), 'utf8')
    const svg = await page.evaluate(
      async ({ source, theme }) => {
        const mermaid = (window as unknown as { mermaid: any }).mermaid
        mermaid.initialize({
          startOnLoad: false,
          theme: 'base',
          themeVariables: theme,
          flowchart: { curve: 'basis', padding: 14, wrappingWidth: 320, nodeSpacing: 40, rankSpacing: 45 },
          securityLevel: 'loose',
        })
        const { svg } = await mermaid.render(`d${Date.now()}`, source)
        return svg as string
      },
      { source, theme: THEME },
    )
    await page.locator('#out').evaluate((el, svg) => {
      el.innerHTML = svg
      // Mermaid setzt width="100%" mit max-width; für das Bild die natürliche Breite verwenden
      const node = el.querySelector('svg')!
      node.style.width = node.style.maxWidth
    }, svg)
    const out = new URL(file.replace(/\.mmd$/, '.png'), DIR).pathname
    await page.locator('#out').screenshot({ path: out })
    console.log(`✓ ${file}`)
  }
  await browser.close()
}

await main()
