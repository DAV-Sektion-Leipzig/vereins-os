import { useState } from 'react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableFooter, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { weekdayShort } from '@/features/ez/dates'
import { reportHref, type ReportResult } from '@/features/ez/kletterhalle/data'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDate } from '@/lib/format'

// T032 (US-EZ-16): Anzahl anwesender Kinder je Training an Orten mit Punktekonto (aktive und inaktive), Zeitraum
// Standard Vormonat; Probetrainings getrennt, Summenzeile; abgesagte Trainings zählen nicht (R22). Keine Namen.
export function KletterhallePage() {
  const { filter, locations, rows, failed } = useLoaderData() as ReportResult
  const navigate = useNavigate()
  const [from, setFrom] = useState(filter.from)
  const [to, setTo] = useState(filter.to)
  const set = (patch: Partial<typeof filter>) => navigate(reportHref({ ...filter, ...patch }), { replace: true })
  const sumParticipants = rows.reduce((s, r) => s + r.participants_present, 0)
  const sumTrials = rows.reduce((s, r) => s + r.trial_count, 0)

  return (
    <section className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Kontrolle Kletterhalle</h1>

      <form
        onSubmit={(e) => {
          e.preventDefault()
          set({ from, to })
        }}
        className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-end"
      >
        <div className="flex flex-col gap-2">
          <Label htmlFor="ez-kh-location">Ort</Label>
          <select id="ez-kh-location" value={filter.location} onChange={(e) => set({ location: e.target.value })} className={selectClassName}>
            {locations.length === 0 && <option value="">Kein Ort mit Punktekonto</option>}
            {locations.map((l) => (
              <option key={l.id} value={l.id}>
                {l.is_active ? l.name : `${l.name} (nicht mehr aktiv)`}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="ez-kh-from">von</Label>
          <Input id="ez-kh-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} onBlur={() => set({ from, to })} className="sm:w-44" />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="ez-kh-to">bis</Label>
          <Input id="ez-kh-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} onBlur={() => set({ from, to })} className="sm:w-44" />
        </div>
      </form>

      {failed ? (
        <LoadFailed />
      ) : rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">Keine Trainings im Zeitraum.</p>
      ) : (
        <div className="overflow-hidden rounded-xl border">
          <Table>
            <caption className="sr-only">Trainings mit anwesenden Teilnehmer:innen und Probetrainings</caption>
            <TableHeader>
              <TableRow className="bg-muted hover:bg-muted">
                <TableHead className="pl-4">Datum</TableHead>
                <TableHead className="whitespace-normal">Gruppe</TableHead>
                <TableHead className="text-right whitespace-normal">Teilnehmer:innen</TableHead>
                <TableHead className="pr-4 text-right whitespace-normal">Probetraining</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.event_id} className="hover:bg-transparent">
                  <TableCell className="pl-4 tabular-nums">
                    <Link to={`/ez/${r.event_id}`} className="underline-offset-4 hover:underline">
                      {weekdayShort(r.start_date)} {formatDate(r.start_date)}
                    </Link>
                  </TableCell>
                  <TableCell className="whitespace-normal">{r.group_name}</TableCell>
                  <TableCell className="text-right tabular-nums">{r.participants_present}</TableCell>
                  <TableCell className="pr-4 text-right tabular-nums">{r.trial_count}</TableCell>
                </TableRow>
              ))}
            </TableBody>
            <TableFooter>
              <TableRow className="font-medium hover:bg-transparent">
                <TableCell className="pl-4" colSpan={2}>
                  Summe ({rows.length} {rows.length === 1 ? 'Training' : 'Trainings'})
                </TableCell>
                <TableCell className="text-right tabular-nums">{sumParticipants}</TableCell>
                <TableCell className="pr-4 text-right tabular-nums">{sumTrials}</TableCell>
              </TableRow>
            </TableFooter>
          </Table>
        </div>
      )}
    </section>
  )
}
