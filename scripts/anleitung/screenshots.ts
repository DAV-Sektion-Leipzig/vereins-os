// Screenshots für die Anleitung (docs/anleitung/bilder). Meldet sich mit den Testzugängen aus supabase/seed.sql an
// und fotografiert die Seiten aus SHOTS. Nur gegen den lokalen Stack oder TEST (Vorschau), nie gegen PROD.
//
// Aufruf:
//   npm run anleitung:screenshots                 alle Bilder, App unter http://localhost:5173; Passwort aus .env.local
//   (oder SEED_TEST_PASSWORD=… setzen); ohne Terminal: GitHub Actions „Anleitung: Bilder erzeugen“ (anleitung-bilder.yml)
//   ANLEITUNG_URL=https://…workers.dev SEED_TEST_PASSWORD=… npm run anleitung:screenshots
//   SEED_TEST_PASSWORD=… npm run anleitung:screenshots -- ez-training  nur Bilder, deren Name den Text enthält
//   SEED_TEST_PASSWORD=… npm run anleitung:screenshots -- --vorbereiten  vorher die Daten der Finanzen vorbereiten
//
// Daten: Seed mit SEED_WITH_EZ=1, SEED_WITH_FI=1, SEED_WITH_DS=1 und SEED_WITH_TK=1 (scripts/anleitung/lokaler-stack.sh).
// Das Dashboard nutzt die Budgetdaten aus supabase/seed-ds.sql (Vorstand mit Vorlage „Budgetpflege“). „--vorbereiten“ erledigt in
// der Oberfläche, was die Bilder der Finanzen zeigen: 1. Halbjahr 2026 berechnen, Tina Trainerin und Hans Helfer als
// Kim Kinderjugend bestätigen, Tina Trainerin abschließen und ihre Abgabe erfassen, eine Auszahlungsrunde anlegen.
// Bereits erledigte Schritte werden übersprungen.
import { existsSync, readFileSync } from 'node:fs'
import { mkdir } from 'node:fs/promises'
import { chromium, type Browser, type BrowserContext, type Page } from 'playwright'

// Lokale Werte wie supabase/seed.sh aus .env.local laden (Datei: ANLEITUNG_ENV, sonst .env.local im Arbeitsordner),
// nur für noch nicht gesetzte Variablen; nichts wird ausgegeben. In GitHub Actions kommt das Passwort aus den Secrets.
function loadEnvFile(path: string) {
  if (!existsSync(path)) return
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const m = /^\s*(?:export\s+)?([A-Z0-9_]+)\s*=\s*(.*)\s*$/.exec(line)
    if (!m || process.env[m[1]] !== undefined) continue
    process.env[m[1]] = m[2].replace(/^(['"])(.*)\1$/, '$2')
  }
}
loadEnvFile(process.env.ANLEITUNG_ENV ?? '.env.local')

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
  vorstand: 'test.vorstand@dav-leipzig.de',
  touren: 'test.touren@dav-leipzig.de',
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
  {
    name: 'ea-aktive',
    zugang: 'referent',
    pfad: '/ea/aktive',
    schritte: (p) => p.getByRole('button', { name: /^Filter/ }).click(),
  },
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

  // Dashboard (Bereich Budget)
  { name: 'ds-dashboard', zugang: 'kiju', pfad: '/dashboard', hoehe: 1250 },
  {
    name: 'ds-posten',
    zugang: 'kiju',
    pfad: '/dashboard',
    schritte: async (p) => {
      await link(p, 'Vergütung Aktive')
      await p.getByRole('heading', { name: 'Vergütung Aktive', level: 1 }).waitFor()
    },
    hoehe: 1000,
  },
  {
    name: 'ds-hinweis',
    zugang: 'kiju',
    pfad: '/dashboard',
    schritte: (p) => klick(p, 'Hinweis zu Fahrten und Freizeiten'),
    dialog: true,
  },
  {
    name: 'ds-umschichtung',
    zugang: 'kiju',
    pfad: '/dashboard',
    schritte: (p) => klick(p, 'Umschichtung beantragen'),
    dialog: true,
  },
  { name: 'ds-dashboard-mobil', zugang: 'kiju', pfad: '/dashboard', mobil: true },
  { name: 'ds-verein', zugang: 'vorstand', pfad: '/dashboard/verein', hoehe: 1350 },
  { name: 'ds-pflege-finanzplan', zugang: 'vorstand', pfad: '/dashboard/budget/pflege' },
  { name: 'ds-pflege-gesamtbudgets', zugang: 'vorstand', pfad: '/dashboard/budget/pflege?reiter=gesamtbudgets' },
  { name: 'ds-pflege-zuordnung', zugang: 'vorstand', pfad: '/dashboard/budget/pflege?reiter=zuordnung', hoehe: 1100 },
  { name: 'ds-pflege-import', zugang: 'vorstand', pfad: '/dashboard/budget/pflege?reiter=import' },
  { name: 'ds-pflege-antraege', zugang: 'vorstand', pfad: '/dashboard/budget/pflege?reiter=antraege' },
  {
    name: 'ad-rechtevorlage-budget',
    zugang: 'admin',
    pfad: '/ad/rechtevorlagen',
    schritte: (p) => p.getByRole('link', { name: 'Budgetpflege' }).first().click(),
    hoehe: 1060,
  },

  // Planungshilfe Touren und Kurse (Seed SEED_WITH_TK=1, Planungen 1–9)
  { name: 'tk-planungen', zugang: 'touren', pfad: '/tk' },
  { name: 'tk-neu', zugang: 'touren', pfad: '/tk/neu' },
  { name: 'tk-planung', zugang: 'touren', pfad: '/tk', schritte: (p) => link(p, 'Hüttentour Stubaier Alpen (Test)'), hoehe: 1000 },
  {
    name: 'tk-anreise',
    zugang: 'touren',
    pfad: '/tk',
    schritte: async (p) => {
      await link(p, 'Hüttentour Stubaier Alpen (Test)')
      await klick(p, /^3\. Termin/)
    },
    hoehe: 1300,
  },
  {
    name: 'tk-kalkulation',
    zugang: 'touren',
    pfad: '/tk',
    schritte: async (p) => {
      await link(p, 'Hüttentour Stubaier Alpen (Test)')
      await klick(p, /^6\. Kalkulation/)
    },
    hoehe: 1500,
  },
  {
    name: 'tk-ausgaben',
    zugang: 'touren',
    pfad: '/tk',
    schritte: async (p) => {
      await link(p, 'Hüttentour Stubaier Alpen (Test)')
      await klick(p, /^Ausgaben/)
    },
    hoehe: 1200,
  },
  {
    name: 'tk-freigeben',
    zugang: 'touren',
    pfad: '/tk',
    schritte: async (p) => {
      await link(p, 'Hüttentour Stubaier Alpen (Test)')
      await klick(p, 'Freigeben')
    },
    dialog: true,
  },
  { name: 'tk-auswertung', zugang: 'geschaeftsstelle', pfad: '/tk/auswertung?jahr=2027' },
  { name: 'tk-planungen-mobil', zugang: 'touren', pfad: '/tk', mobil: true },
]

async function anmelden(page: Page, email: string) {
  await page.goto(`${BASE}/login`)
  await page.getByLabel('Login-Adresse').fill(email)
  await page.getByLabel('Passwort', { exact: true }).fill(PASSWORD!)
  await page.getByRole('button', { name: 'Anmelden' }).click()
  await page.waitForURL(`${BASE}/`)
}

const sichtbar = async (page: Page, name: string) => {
  const button = page.getByRole('button', { name, exact: true }).first()
  return (await button.isVisible()) && (await button.isEnabled())
}

// Bestätigungsdialog (ConfirmDialog/FormDialog): letzter Knopf im Dialog
async function dialogBestaetigen(page: Page, name: string | RegExp) {
  await page.getByRole('dialog').getByRole('button', { name }).last().click()
  await page.getByRole('dialog').waitFor({ state: 'detached' })
  await page.waitForLoadState('networkidle')
}

async function abrechnungOeffnen(page: Page, name: string) {
  await page.goto(`${BASE}/fi?hj=2026-1`)
  await page.waitForLoadState('networkidle')
  await link(page, name)
  await page.waitForURL(/\/fi\/abrechnung\//)
  await page.getByRole('heading', { name }).waitFor()
  await page.waitForLoadState('networkidle')
}

/** Daten der Finanzen für die Bilder vorbereiten (idempotent). */
async function finanzenVorbereiten(browser: Browser) {
  const als = async (zugang: keyof typeof ZUGANG, schritte: (page: Page) => Promise<void>) => {
    const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, locale: 'de-DE' })
    const page = await context.newPage()
    await anmelden(page, ZUGANG[zugang])
    await schritte(page)
    await context.close()
  }
  await als('geschaeftsstelle', async (p) => {
    await p.goto(`${BASE}/fi?hj=2026-1`)
    await p.waitForLoadState('networkidle')
    if (await p.getByRole('link', { name: 'Tina Trainerin', exact: true }).count()) return
    await klick(p, 'Berechnen')
    await dialogBestaetigen(p, 'Berechnen')
    console.log('· 1. Halbjahr 2026 berechnet')
  })
  await als('kiju', async (p) => {
    for (const name of ['Tina Trainerin', 'Hans Helfer']) {
      await abrechnungOeffnen(p, name)
      if (!(await sichtbar(p, 'Bestätigen'))) continue
      await klick(p, 'Bestätigen')
      await dialogBestaetigen(p, 'Bestätigen')
      console.log(`· ${name} bestätigt`)
    }
  })
  await als('geschaeftsstelle', async (p) => {
    await abrechnungOeffnen(p, 'Tina Trainerin')
    if (await sichtbar(p, 'Abschließen')) {
      await klick(p, 'Abschließen')
      await dialogBestaetigen(p, 'Abschließen')
      console.log('· Tina Trainerin abgeschlossen')
      await abrechnungOeffnen(p, 'Tina Trainerin')
    }
    if (await sichtbar(p, 'Abgabe erfassen')) {
      await klick(p, 'Abgabe erfassen')
      await p.fill('#fi-submitted-on', '2026-07-20')
      await dialogBestaetigen(p, 'Speichern')
      console.log('· Abgabe von Tina Trainerin erfasst')
    }
    await p.goto(`${BASE}/fi/auszahlungen`)
    await p.waitForLoadState('networkidle')
    if (await p.locator('main a[href^="/fi/auszahlungen/"]').count()) return
    await klick(p, 'Neue Runde')
    await dialogBestaetigen(p, 'Anlegen')
    console.log('· Auszahlungsrunde angelegt')
  })
}

async function main() {
  const args = process.argv.slice(2)
  const filter = args.filter((a) => a !== '--vorbereiten')
  const shots = filter.length ? SHOTS.filter((s) => filter.some((f) => s.name.includes(f))) : SHOTS
  await mkdir(OUT, { recursive: true })

  const browser = await chromium.launch({ executablePath: process.env.PLAYWRIGHT_CHROMIUM_PATH, args: ['--lang=de-DE'], env: { ...process.env, LANG: 'de_DE.UTF-8', LANGUAGE: 'de' } })
  if (args.includes('--vorbereiten')) await finanzenVorbereiten(browser)
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
