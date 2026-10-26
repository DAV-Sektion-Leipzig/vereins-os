// Screenshots für die Anleitung (docs/anleitung/bilder). Meldet sich mit den Testzugängen aus supabase/seed.sql an
// und fotografiert die Seiten aus SHOTS. Nur gegen den lokalen Stack oder TEST (Vorschau), nie gegen PROD.
//
// Aufruf:
//   SEED_TEST_PASSWORD=… npm run anleitung:screenshots                 alle Bilder, App unter http://localhost:5173
//   ANLEITUNG_URL=https://…workers.dev SEED_TEST_PASSWORD=… npm run anleitung:screenshots
//   SEED_TEST_PASSWORD=… npm run anleitung:screenshots -- ez-training  nur Bilder, deren Name den Text enthält
//
// Daten: Seed mit SEED_WITH_EZ=1 und SEED_WITH_FI=1; für die Finanzen vorher in der Oberfläche das 1. Halbjahr 2026
// berechnen, Tina Trainerin und Hans Helfer als Kim Kinderjugend bestätigen, Tina Trainerin abschließen und die Abgabe
// erfassen sowie eine Auszahlungsrunde anlegen (docs/anleitung/README.md, Abschnitt „Anleitung aktualisieren“).
import { mkdir } from 'node:fs/promises'
import { chromium, type BrowserContext, type Page } from 'playwright'

const BASE = (process.env.ANLEITUNG_URL ?? 'http://localhost:5173').replace(/\/$/, '')
const PASSWORD = process.env.SEED_TEST_PASSWORD
const OUT = new URL('../../docs/anleitung/bilder/', import.meta.url)

if (new URL(BASE).host === 'vereins-os.sektion-leipzig.workers.dev') {
  // PROD; Vorschau-Deployments haben ein Präfix (…-vereins-os.sektion-leipzig.workers.dev).
  console.error('Screenshots nicht gegen PROD.')
  process.exit(1)
}
if (!PASSWORD) {
  console.error('SEED_TEST_PASSWORD fehlt.')
  process.exit(1)
}

// Testzugänge aus supabase/seed.sql
const ZUGANG = {
  admin: 'test.admin@dav-leipzig.de',
  geschaeftsstelle: 'test.geschaeftsstelle@dav-leipzig.de',
  referent: 'test.referent@dav-leipzig.de',
  kiju: 'test.kiju@dav-leipzig.de',
} as const

// Feste IDs aus supabase/seed.sql und seed-ez.sql
const ID = {
  rita: 'a0000000-0000-4000-8000-000000000009',
  lena: 'a0000000-0000-4000-8000-000000000019',
  mia: 'a0000000-0000-4000-8000-000000000023',
  klettergruppe: 'c0000000-0000-4000-8000-000000000003',
  jugendcup: 'f0000000-0000-4000-8000-000000000006',
}

type Shot = {
  name: string
  zugang: keyof typeof ZUGANG | null
  pfad: string
  schritte?: (page: Page) => Promise<void>
  /** Höhe des Ausschnitts; Standard ist die sichtbare Seite (800 px). */
  hoehe?: number
  /** Nur das Dialogfenster fotografieren. */
  dialog?: boolean
  mobil?: boolean
}

const klick = (page: Page, name: string | RegExp) => page.getByRole('button', { name }).first().click()
const link = (page: Page, name: string) => page.getByRole('link', { name, exact: true }).first().click()

// Training der Klettergruppe ausfüllen und einige Anwesende ankreuzen (nicht speichern)
async function trainingErfassen(p: Page) {
  await klick(p, 'Training')
  await p.getByLabel('Gruppe').selectOption({ label: 'Klettergruppe Test' })
  await p.getByLabel('Datum').fill('2026-10-27')
  await p.getByLabel('Ort').selectOption({ label: 'Kletterhalle Test' })
  for (const name of ['Rita Referentin', 'Mia Fiktiv', 'Ella Klettertest', 'Finn Klettertest', 'Ida Klettertest']) {
    await p.getByRole('checkbox', { name }).check()
  }
  await p.locator('h1').click()
}

const SHOTS: Shot[] = [
  // Erste Schritte (alle)
  { name: 'anmelden', zugang: null, pfad: '/login' },
  { name: 'passwort-vergessen', zugang: null, pfad: '/passwort-vergessen' },
  { name: 'start-geschaeftsstelle', zugang: 'geschaeftsstelle', pfad: '/' },
  { name: 'start-referent', zugang: 'referent', pfad: '/' },

  // Administration (Admin)
  { name: 'ad-personen', zugang: 'admin', pfad: '/ad' },
  { name: 'ad-person-neu', zugang: 'admin', pfad: '/ad/personen/neu' },
  { name: 'ad-person', zugang: 'admin', pfad: `/ad/personen/${ID.rita}`, hoehe: 1100 },
  {
    name: 'ad-vorlage-zuweisen',
    zugang: 'admin',
    pfad: `/ad/personen/${ID.rita}`,
    schritte: async (p) => {
      await klick(p, 'Vorlage hinzufügen')
      await p.getByRole('heading', { name: 'Rechtevorlagen' }).scrollIntoViewIfNeeded()
    },
  },
  { name: 'ad-rechtevorlagen', zugang: 'admin', pfad: '/ad/rechtevorlagen' },
  {
    name: 'ad-rechtevorlage',
    zugang: 'admin',
    pfad: '/ad/rechtevorlagen',
    schritte: (p) => p.getByRole('link', { name: 'Referent:in' }).first().click(),
    hoehe: 1060,
  },
  { name: 'ad-eigenschaftsarten', zugang: 'admin', pfad: '/ad/eigenschaftsarten' },
  { name: 'ad-qualifikationsarten', zugang: 'admin', pfad: '/ad/qualifikationsarten' },
  { name: 'ad-saetze', zugang: 'admin', pfad: '/ad/saetze' },
  { name: 'ad-abrechnungsarten', zugang: 'admin', pfad: '/ad/abrechnungsarten' },
  { name: 'ad-auszahlung', zugang: 'admin', pfad: '/ad/auszahlung', hoehe: 1000 },
  { name: 'ad-protokoll', zugang: 'admin', pfad: '/ad/protokoll' },

  // Ehrenamtsmanagement
  { name: 'ea-aktive', zugang: 'referent', pfad: '/ea/aktive' },
  { name: 'ea-person', zugang: 'referent', pfad: `/ea/aktive/${ID.lena}` },
  { name: 'ea-person-neu', zugang: 'referent', pfad: '/ea/aktive/neu' },
  {
    name: 'ea-verlaengern',
    zugang: 'geschaeftsstelle',
    pfad: `/ea/aktive/${ID.lena}`,
    schritte: (p) => klick(p, 'Verlängern'),
    dialog: true,
  },
  {
    name: 'ea-status',
    zugang: 'referent',
    pfad: `/ea/aktive/${ID.lena}`,
    schritte: (p) => klick(p, 'Status ändern'),
    dialog: true,
  },
  { name: 'ea-ablauf', zugang: 'referent', pfad: '/ea/ablauf' },
  { name: 'ea-gremien', zugang: 'geschaeftsstelle', pfad: '/ea/gremien' },
  { name: 'ea-stammdaten', zugang: 'geschaeftsstelle', pfad: '/ea/stammdaten' },

  // Gruppen
  { name: 'gr-gruppen', zugang: 'geschaeftsstelle', pfad: '/gr' },
  { name: 'gr-gruppe', zugang: 'geschaeftsstelle', pfad: `/gr/gruppen/${ID.klettergruppe}`, hoehe: 1000 },
  { name: 'gr-betreuung', zugang: 'geschaeftsstelle', pfad: `/gr/gruppen/${ID.klettergruppe}?reiter=betreuung` },
  { name: 'gr-aufnehmen', zugang: 'geschaeftsstelle', pfad: `/gr/gruppen/${ID.klettergruppe}/aufnehmen` },
  { name: 'gr-aufnahmen-offen', zugang: 'geschaeftsstelle', pfad: '/gr/aufnahmen' },
  { name: 'gr-person', zugang: 'geschaeftsstelle', pfad: `/gr/personen/${ID.mia}`, hoehe: 1200 },

  // Anwesenheitserfassung
  { name: 'ez-einsaetze', zugang: 'referent', pfad: '/ez' },
  { name: 'ez-neu', zugang: 'referent', pfad: '/ez/neu' },
  { name: 'ez-training', zugang: 'referent', pfad: '/ez/neu', schritte: trainingErfassen, hoehe: 1200 },
  {
    name: 'ez-training-mobil',
    zugang: 'referent',
    pfad: '/ez/neu',
    schritte: async (p) => {
      await trainingErfassen(p)
      await p.getByText('Anwesenheit', { exact: true }).evaluate((el) => window.scrollTo(0, el.getBoundingClientRect().top + window.scrollY - 16))
    },
    mobil: true,
  },
  { name: 'ez-einsatz', zugang: 'referent', pfad: `/ez/${ID.jugendcup}` },
  { name: 'ez-kletterhalle', zugang: 'geschaeftsstelle', pfad: '/ez/kletterhalle?von=2026-10-01&bis=2026-10-31' },

  // Finanzen
  { name: 'fi-abrechnungen-referent', zugang: 'kiju', pfad: '/fi?hj=2026-1' },
  {
    name: 'fi-abrechnung-referent',
    zugang: 'kiju',
    pfad: '/fi?hj=2026-1',
    schritte: (p) => link(p, 'Clara Ablauf'),
    hoehe: 1100,
  },
  { name: 'fi-abrechnungen', zugang: 'geschaeftsstelle', pfad: '/fi?hj=2026-1' },
  {
    name: 'fi-abrechnung',
    zugang: 'geschaeftsstelle',
    pfad: '/fi?hj=2026-1',
    schritte: (p) => link(p, 'Tina Trainerin'),
    hoehe: 1100,
  },
  {
    name: 'fi-berechnen',
    zugang: 'geschaeftsstelle',
    pfad: '/fi?hj=2026-1',
    schritte: (p) => klick(p, 'Berechnen'),
    dialog: true,
  },
  { name: 'fi-auszahlungsrunden', zugang: 'geschaeftsstelle', pfad: '/fi/auszahlungen' },
  {
    name: 'fi-auszahlungsrunde',
    zugang: 'geschaeftsstelle',
    pfad: '/fi/auszahlungen',
    schritte: (p) => p.locator('main a[href^="/fi/auszahlungen/"]').first().click(),
    hoehe: 1000,
  },
  { name: 'fi-kletterhalle', zugang: 'geschaeftsstelle', pfad: '/fi/kletterhalle?von=2026-10-01&bis=2026-10-31', hoehe: 1000 },
]

async function anmelden(page: Page, email: string) {
  await page.goto(`${BASE}/login`)
  await page.getByLabel('Login-Adresse').fill(email)
  await page.getByLabel('Passwort', { exact: true }).fill(PASSWORD!)
  await page.getByRole('button', { name: 'Anmelden' }).click()
  await page.waitForURL(`${BASE}/`)
}

async function main() {
  const filter = process.argv.slice(2)
  const shots = filter.length ? SHOTS.filter((s) => filter.some((f) => s.name.includes(f))) : SHOTS
  await mkdir(OUT, { recursive: true })

  const browser = await chromium.launch({ executablePath: process.env.PLAYWRIGHT_CHROMIUM_PATH, args: ['--lang=de-DE'], env: { ...process.env, LANG: 'de_DE.UTF-8', LANGUAGE: 'de' } })
  let failed = 0
  for (const zugang of [null, ...Object.keys(ZUGANG)] as (keyof typeof ZUGANG | null)[]) {
    const own = shots.filter((s) => s.zugang === zugang)
    if (!own.length) continue
    // Anmeldung einmal je Zugang; jedes Bild bekommt einen frischen Kontext mit dieser Sitzung, damit gespeicherte
    // Formularentwürfe (US-EZ-18) oder offene Formulare das nächste Bild nicht beeinflussen.
    let storageState: Awaited<ReturnType<BrowserContext['storageState']>> | undefined
    if (zugang) {
      const login = await browser.newContext()
      await anmelden(await login.newPage(), ZUGANG[zugang])
      storageState = await login.storageState()
      await login.close()
    }
    for (const shot of own) {
      const context = await browser.newContext({
        viewport: shot.mobil ? { width: 390, height: 844 } : { width: 1280, height: 800 },
        locale: 'de-DE',
        storageState,
      })
      const page = await context.newPage()
      try {
        await page.goto(BASE + shot.pfad)
        await page.waitForLoadState('networkidle')
        if (shot.schritte) {
          await shot.schritte(page)
          await page.waitForLoadState('networkidle')
        }
        // Fokusrahmen entfernen und Einblendungen (Dialoge) abwarten
        await page.evaluate(() => (document.activeElement as HTMLElement | null)?.blur())
        await page.waitForTimeout(shot.dialog ? 800 : 400)
        const path = new URL(`${shot.name}.png`, OUT).pathname
        if (shot.dialog) {
          await page.getByRole('dialog').screenshot({ path })
        } else if (shot.mobil) {
          await page.screenshot({ path })
        } else {
          // Inhalt ist 976 px breit und zentriert; seitlichen Leerraum abschneiden
          // Unten nur bis zum Ende des Inhalts, damit kurze Seiten keinen weißen Rand bekommen
          const { scrollY, end } = await page.evaluate(() => ({
            scrollY: window.scrollY,
            end: Math.ceil(
              Math.max(...[...document.body.querySelectorAll('*')].filter((el) => !el.children.length && el.tagName !== 'SECTION').map((el) => el.getBoundingClientRect().bottom)) + window.scrollY + 24,
            ),
          }))
          const clip = shot.hoehe ? { y: 0, height: Math.min(shot.hoehe, end) } : { y: scrollY, height: Math.min(800, end - scrollY) }
          await page.screenshot({ path, fullPage: true, clip: { x: 136, width: 1008, ...clip } })
        }
        console.log(`✓ ${shot.name}`)
      } catch (error) {
        failed++
        console.error(`✗ ${shot.name}: ${(error as Error).message.split('\n')[0]}`)
      } finally {
        await context.close()
      }
    }
  }
  await browser.close()
  if (failed) process.exit(1)
}

await main()
