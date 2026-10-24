// Datum und Zeit ohne Zeitzone, immer Ortszeit Leipzig (spec.md EZ 8). Datenbankwerte: `YYYY-MM-DD`, `HH:MM[:SS]`.
import { formatDate, WEEKDAYS } from '@/lib/format'

/** Heute in Europe/Berlin als `YYYY-MM-DD`. */
export function todayIso(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Berlin', year: 'numeric', month: '2-digit', day: '2-digit' }).format(
    new Date(),
  )
}

/** ISO-Wochentag (1 = Montag) eines Datums `YYYY-MM-DD`. */
export function isoWeekday(date: string): number {
  const [y, m, d] = date.split('-').map(Number)
  const day = new Date(Date.UTC(y, m - 1, d)).getUTCDay()
  return day === 0 ? 7 : day
}

export function weekdayShort(date: string): string {
  return WEEKDAYS.find((w) => w.value === isoWeekday(date))?.short ?? ''
}

/** `HH:MM` aus `HH:MM:SS`. */
export function hhmm(time: string | null | undefined): string {
  return time ? time.slice(0, 5) : ''
}

/** „TT.MM.JJJJ“ bzw. Zeitraum „07.–09.11.2026“ (spec.md 6). */
export function formatEventDate(start: string, end: string | null): string {
  if (!end) return formatDate(start)
  const [sy, sm] = start.split('-')
  const [ey, em] = end.split('-')
  const s = formatDate(start)
  const e = formatDate(end)
  if (sy === ey && sm === em) return `${s.slice(0, 3)}–${e}`
  if (sy === ey) return `${s.slice(0, 6)}–${e}`
  return `${s}–${e}`
}
