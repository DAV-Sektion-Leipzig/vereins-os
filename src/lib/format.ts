// Datum TT.MM.JJJJ und Zeit HH:MM in Europe/Berlin (spec.md AD Abschnitt 6).

const TIME_ZONE = 'Europe/Berlin'

const dateFormat = new Intl.DateTimeFormat('de-DE', {
  timeZone: TIME_ZONE,
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
})

const timeFormat = new Intl.DateTimeFormat('de-DE', {
  timeZone: TIME_ZONE,
  hour: '2-digit',
  minute: '2-digit',
})

function toDate(value: Date | string): Date {
  return typeof value === 'string' ? new Date(value) : value
}

/** Reines Datum aus der Datenbank (`date`, z. B. „2026-03-01“) ohne Zeitzonenverschiebung. */
function fromDateOnly(value: string): Date {
  const [year, month, day] = value.split('-').map(Number)
  return new Date(Date.UTC(year, month - 1, day, 12))
}

export function formatDate(value: Date | string): string {
  if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return dateFormat.format(fromDateOnly(value))
  }
  return dateFormat.format(toDate(value))
}

export function formatTime(value: Date | string): string {
  return timeFormat.format(toDate(value))
}

export function formatDateTime(value: Date | string): string {
  return `${formatDate(value)} ${formatTime(value)}`
}

export type PersonNameParts = {
  first_name: string
  preferred_name?: string | null
  last_name: string
}

/** „Rufname Nachname“, sonst „Vorname Nachname“ (spec.md AD Abschnitt 6, US-AD-24). */
export function personName({ first_name, preferred_name, last_name }: PersonNameParts): string {
  return `${preferred_name?.trim() || first_name} ${last_name}`
}

/** Wochentage nach ISO (1 = Montag), Kürzel und ausgeschrieben (Trainingszeiten, GR spec.md 2.1). */
export const WEEKDAYS: { value: number; short: string; long: string }[] = [
  { value: 1, short: 'Mo', long: 'Montag' },
  { value: 2, short: 'Di', long: 'Dienstag' },
  { value: 3, short: 'Mi', long: 'Mittwoch' },
  { value: 4, short: 'Do', long: 'Donnerstag' },
  { value: 5, short: 'Fr', long: 'Freitag' },
  { value: 6, short: 'Sa', long: 'Samstag' },
  { value: 7, short: 'So', long: 'Sonntag' },
]

export function weekdayShort(value: number): string {
  return WEEKDAYS.find((d) => d.value === value)?.short ?? ''
}

/** Uhrzeit aus der Datenbank (`time`, z. B. „16:30:00“) als HH:MM. */
export function formatClock(value: string): string {
  return value.slice(0, 5)
}

/** Heute in Europe/Berlin als `YYYY-MM-DD` (wie gr_today in der Datenbank). */
export function todayIso(): string {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: TIME_ZONE }).format(new Date())
}

/** Alter in vollen Jahren am Stichtag; nur bei lesbarem Geburtsdatum (W2 GR). */
export function ageOn(birthDate: string, day: string = todayIso()): number {
  const [by, bm, bd] = birthDate.split('-').map(Number)
  const [y, m, d] = day.split('-').map(Number)
  return y - by - (m < bm || (m === bm && d < bd) ? 1 : 0)
}
