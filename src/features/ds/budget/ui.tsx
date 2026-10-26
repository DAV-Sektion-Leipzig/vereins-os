// Bausteine der Budget-Sicht (sichten.md, Skizze „Dashboard Kinder und Jugend“): Ampel mit Form und Wort (R6),
// Balken mit Strich für den Jahresfortschritt (R7) und schraffierter Vorschau (R18), Vorjahr mit Pfeil (R20).
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'
import type { Ampel } from '@/features/ds/budget/data'

const money = new Intl.NumberFormat('de-DE', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
const moneyCents = new Intl.NumberFormat('de-DE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
const percent = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 0 })

/** Ganze Euro für Übersichten („48.000 €“). */
export function euro(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') return '–'
  return `${money.format(Math.round(Number(value)))} €`
}

/** Euro mit Cent für Einzelbuchungen („1.234,56 €“). */
export function euroCents(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') return '–'
  return `${moneyCents.format(Number(value))} €`
}

export function pct(value: number | null | undefined): string {
  if (value === null || value === undefined) return '–'
  return `${percent.format(value)} %`
}

export const AMPEL: Record<Exclude<Ampel, null>, { shape: string; label: string; rule: string; className: string; fill: string }> = {
  ok: {
    shape: '●',
    label: 'im Plan',
    rule: 'Verbrauch unter 80 % des aktuellen Plans',
    className: 'bg-status-active-bg text-status-active',
    fill: 'bg-primary-hover',
  },
  warn: {
    shape: '▲',
    label: 'knapp',
    rule: 'Verbrauch 80 bis 100 % des aktuellen Plans',
    className: 'bg-status-locked-bg text-status-locked',
    fill: 'bg-chart-3',
  },
  over: {
    shape: '■',
    label: 'über Plan',
    rule: 'Verbrauch über 100 % des aktuellen Plans',
    className: 'bg-destructive/10 text-destructive',
    fill: 'bg-destructive',
  },
  no_plan: {
    shape: '■',
    label: 'ohne Budget',
    rule: 'Ausgaben ohne Plan',
    className: 'bg-destructive/10 text-destructive',
    fill: 'bg-destructive',
  },
}

export function AmpelBadge({ ampel }: { ampel: Ampel }) {
  if (!ampel) return <span className="text-sm text-muted-foreground">–</span>
  const a = AMPEL[ampel]
  return (
    <span
      title={a.rule}
      className={cn('inline-flex h-5 items-center gap-1 rounded-full px-2 text-xs font-medium whitespace-nowrap', a.className)}
    >
      <span aria-hidden="true">{a.shape}</span>
      {a.label}
    </span>
  )
}

/** Hinweis ▲ „mit Vorschau über Plan“ (sichten.md B8). */
export function PreviewOverBadge() {
  return (
    <span
      title="Ist und Vorschau zusammen übersteigen den aktuellen Plan"
      className="inline-flex h-5 items-center gap-1 rounded-full bg-status-locked-bg px-2 text-xs font-medium whitespace-nowrap text-status-locked"
    >
      <span aria-hidden="true">▲</span>
      mit Vorschau über Plan
    </span>
  )
}

type BarProps = {
  plan: number
  actual: number
  preview?: number
  /** Jahresfortschritt in % (R7). */
  progress?: number | null
  ampel: Ampel
  label: string
}

/** Balken: Ist bis höchstens 100 % des Plans, Vorschau schraffiert dahinter, Strich beim Jahresfortschritt. */
export function BudgetBar({ plan, actual, preview = 0, progress, ampel, label }: BarProps) {
  const base = plan > 0 ? plan : Math.max(actual + preview, 1)
  const actualPct = Math.max(0, Math.min(100, (actual / base) * 100))
  const previewPct = Math.max(0, Math.min(100 - actualPct, (preview / base) * 100))
  const fill = ampel ? AMPEL[ampel].fill : 'bg-muted-foreground'
  return (
    <div role="img" aria-label={label} className="relative h-2.5 w-full rounded-full bg-status-none-bg">
      <div className={cn('absolute inset-y-0 left-0 rounded-full', fill)} style={{ width: `${actualPct}%` }} />
      {previewPct > 0 && (
        <div
          className="absolute inset-y-0 rounded-r-full border border-dashed border-status-invited"
          style={{
            left: `${actualPct}%`,
            width: `${previewPct}%`,
            background: 'repeating-linear-gradient(135deg, var(--status-invited-bg) 0 4px, #ffffff 4px 8px)',
          }}
        />
      )}
      {progress !== null && progress !== undefined && (
        <div
          aria-hidden="true"
          className="absolute -inset-y-1 w-0.5 bg-foreground"
          style={{ left: `${Math.max(0, Math.min(100, progress))}%` }}
        />
      )}
    </div>
  )
}

/** Vorjahr klein mit Pfeil (sichten.md); bei Ausgaben ist mehr als im Vorjahr ▲. */
export function PrevYear({ value, current, found, date }: { value: number | null; current: number; found: boolean; date?: string }) {
  if (!found || value === null) return <span className="text-xs text-muted-foreground">neu</span>
  const diff = current - value
  const arrow = Math.abs(diff) < 0.5 ? '=' : diff > 0 ? '▲' : '▼'
  return (
    <span className="text-xs text-muted-foreground">
      <span aria-hidden="true">{arrow} </span>Vorjahr{date ? ` ${date}` : ''}: {euro(value)}
    </span>
  )
}

export function Tile({ label, value, children }: { label: string; value: ReactNode; children?: ReactNode }) {
  return (
    <div className="flex flex-col gap-1 rounded-xl border bg-card px-4 py-3">
      <span className="text-sm text-muted-foreground">{label}</span>
      <span className="text-2xl font-semibold tabular-nums">{value}</span>
      {children && <span className="text-xs text-muted-foreground">{children}</span>}
    </div>
  )
}

/** Abschnittsüberschrift mit Nummer wie in der Skizze (① Zu tun, ② Budget …). */
export function BlockHeading({ id, children, sub }: { id: string; children: ReactNode; sub?: ReactNode }) {
  return (
    <div className="flex flex-col gap-0.5">
      <h2 id={id} className="font-semibold">
        {children}
      </h2>
      {sub && <div className="text-sm text-muted-foreground">{sub}</div>}
    </div>
  )
}

export const textareaClassName =
  'min-h-20 w-full rounded-lg border border-input bg-background px-2.5 py-1.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm'

/** A4 quer beim Drucken der Budget-Seiten (US-DS-19). */
export function PrintLandscape() {
  return <style>{'@media print { @page { size: A4 landscape; margin: 12mm; } }'}</style>
}
