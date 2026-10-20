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
