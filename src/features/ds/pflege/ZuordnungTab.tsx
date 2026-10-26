import { useMemo, useState } from 'react'
import { PencilIcon, PlusIcon, XIcon } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { parseZuordnung } from '@/features/ds/budget/parse/zuordnung'
import { euroCents, textareaClassName } from '@/features/ds/budget/ui'
import type { ItemRow, PflegeData, RuleRow } from '@/features/ds/pflege/data'
import { FilePick, Note, RULE_STATUS, useAction } from '@/features/ds/pflege/shared'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { FormError, selectClassName } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'

const RULE_TYPE: Record<RuleRow['rule_type'], string> = {
  booking: 'Einzelbuchung',
  account: 'Einzelkonto',
  main_account: 'Hauptkonto',
  range: 'Bereich',
}

type CsvError = { line?: number; type: string; value?: string; kind?: string }
type CsvResult = { ok: boolean; errors?: CsvError[]; hints?: { type: string; name?: string; count?: number; value?: string }[]; rules?: number }

const CSV_ERRORS: Record<string, string> = {
  art_invalid: 'Art unbekannt (Ausgabe oder Einnahme)',
  item_unknown: 'Budgetposten nicht im Finanzplan',
  account_invalid: 'Kontoangabe ungültig',
  duplicate: 'Kontoangabe doppelt',
  date_invalid: 'Datum ungültig',
  amount_invalid: 'Betrag ungültig',
  booking_needs_account: 'Einzelbuchung braucht ein Einzelkonto',
  duplicate_without_row: 'Doppelter Postenname ohne Posten darüber',
}

const CSV_HINTS: Record<string, string> = {
  status_unknown: 'Status unbekannt, als „ok“ übernommen',
  several_groups: 'Budgetposten mehreren Gesamtbudgets zugeordnet, das erste gilt',
}

// US-FI-24, -25 (R2, R11): Regeln mit Filter, anlegen, ändern, beenden, Verlauf; Übernahme der zuordnung.csv.
export function ZuordnungTab({ data }: { data: PflegeData }) {
  const { year, rules, items, groups } = data
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [history, setHistory] = useState(false)
  const [edit, setEdit] = useState<RuleRow | 'new' | null>(null)
  const [end, setEnd] = useState<RuleRow | null>(null)
  const [csvRows, setCsvRows] = useState<unknown[] | null>(null)
  const [csvResult, setCsvResult] = useState<CsvResult | null>(null)
  const action = useAction()

  const itemLabel = useMemo(() => {
    const groupName = new Map(groups.map((g) => [g.id, g.name]))
    return new Map(items.map((i) => [i.id, `${groupName.get(i.group_id) ?? ''} · ${i.name}`]))
  }, [items, groups])

  const visible = rules.filter((r) => {
    if (!history && r.valid_to) return false
    if (status && r.status !== status) return false
    const q = search.trim().toLowerCase()
    if (!q) return true
    return [r.account_text, r.account_label, r.note, r.item_id ? itemLabel.get(r.item_id) : 'ohne Budgetposten', r.cost_centers.join(',')]
      .some((v) => (v ?? '').toLowerCase().includes(q))
  })

  async function readCsv(file: File) {
    setCsvResult(null)
    const parsed = parseZuordnung(await file.arrayBuffer())
    if (!parsed.ok) return action.setError('In der Datei fehlt die Kopfzeile mit „Konto“ und „Budgetposten“.')
    setCsvRows(parsed.rows)
  }

  async function importCsv() {
    const res = await action.run<CsvResult>('fi_budget_rules_import_csv', { p_year: year, p_rows: csvRows })
    setCsvRows(null)
    if (!res) return
    setCsvResult(res.data)
    if (res.data.ok) toast.success(`zuordnung.csv übernommen: ${res.data.rules} Regeln.`)
  }

  if (items.length === 0) return <p className="text-sm text-muted-foreground">Zuerst den Finanzplan einlesen.</p>

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted-foreground">
        Vorrang: Einzelbuchung vor Einzelkonto („6326 3“) vor Hauptkonto („6326“) vor Bereich („4000-7999“, engster zuerst); mit
        Kostenstelle vor ohne. Nur Buchungen auf Konten mit Regel werden ausgewertet.
      </p>
      <div className="flex flex-wrap items-end gap-3">
        <Input type="search" aria-label="Regeln durchsuchen" placeholder="Suche: Konto, Posten, Hinweis" value={search} onChange={(e) => setSearch(e.target.value)} className="sm:max-w-64" />
        <select aria-label="Status" className={selectClassName} value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">alle Status</option>
          {Object.entries(RULE_STATUS).map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={history} onChange={(e) => setHistory(e.target.checked)} />
          beendete anzeigen
        </label>
        <span className="flex-1" />
        <Button onClick={() => setEdit('new')}>
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Neue Regel
        </Button>
        <FilePick accept=".csv,text/csv" label="zuordnung.csv übernehmen" onFile={readCsv} disabled={action.pending} />
      </div>
      <FormError text={action.error} />
      {csvResult && !csvResult.ok && (
        <Note tone="warn">
          Nicht übernommen. Bitte die Datei korrigieren:
          <ul className="mt-1 list-disc pl-5">
            {(csvResult.errors ?? []).map((e, i) => (
              <li key={i}>
                Zeile {e.line ?? '–'}: {CSV_ERRORS[e.type] ?? e.type}
                {e.value ? ` („${e.value}“)` : ''}
              </li>
            ))}
          </ul>
        </Note>
      )}
      {csvResult?.ok && (csvResult.hints ?? []).length > 0 && (
        <Note>
          Hinweise:
          <ul className="mt-1 list-disc pl-5">
            {(csvResult.hints ?? []).map((h, i) => (
              <li key={i}>
                {h.type === 'item_without_account'
                  ? `Budgetposten ohne Konto: ${h.name}`
                  : h.type === 'other_years'
                    ? `${h.count} Einzelbuchungsregeln aus anderen Jahren übersprungen`
                    : h.type === 'no_range'
                      ? 'Keine Auffangregel für einen Kontenbereich (z. B. 4000-7999)'
                      : `${CSV_HINTS[h.type] ?? h.type}${h.name ? `: ${h.name}` : ''}${h.value ? `: ${h.value}` : ''}`}
              </li>
            ))}
          </ul>
        </Note>
      )}

      <div className="overflow-x-auto rounded-xl border">
        <Table className="min-w-[52rem]">
          <TableHeader>
            <TableRow className="bg-muted hover:bg-muted">
              <TableHead className="pl-4">Konto</TableHead>
              <TableHead>Art</TableHead>
              <TableHead>Kostenstelle</TableHead>
              <TableHead>Budgetposten</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Hinweis</TableHead>
              <TableHead className="pr-4">
                <span className="sr-only">Aktionen</span>
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {visible.map((r) => (
              <TableRow key={r.id} className={r.valid_to ? 'text-muted-foreground' : ''}>
                <TableCell className="pl-4 tabular-nums">
                  {r.account_text}
                  {r.account_label && <span className="block text-xs text-muted-foreground">{r.account_label}</span>}
                </TableCell>
                <TableCell>
                  {RULE_TYPE[r.rule_type]}
                  {r.rule_type === 'booking' && (
                    <span className="block text-xs text-muted-foreground">
                      {r.b_date ? formatDate(r.b_date) : ''} {r.b_receipt ?? ''} {r.b_amount !== null ? `${euroCents(r.b_amount)} ${r.b_side ?? ''}` : ''}
                    </span>
                  )}
                </TableCell>
                <TableCell>{r.cost_centers.length ? r.cost_centers.join(', ') : '–'}</TableCell>
                <TableCell className="max-w-64 whitespace-normal">{r.item_id ? itemLabel.get(r.item_id) ?? '–' : 'ohne Budgetposten'}</TableCell>
                <TableCell>{RULE_STATUS[r.status]}</TableCell>
                <TableCell className="max-w-64 whitespace-normal">
                  {r.note ?? r.reason ?? '–'}
                  <span className="block text-xs text-muted-foreground">
                    seit {formatDateTime(r.valid_from)}
                    {r.valid_to ? ` · beendet ${formatDateTime(r.valid_to)}` : ''}
                    {r.comment ? ` · ${r.comment}` : ''}
                  </span>
                </TableCell>
                <TableCell className="pr-4 text-right whitespace-nowrap">
                  {!r.valid_to && r.rule_type !== 'booking' && (
                    <Button variant="ghost" size="icon-sm" aria-label={`Regel ${r.account_text} ändern`} onClick={() => setEdit(r)}>
                      <PencilIcon aria-hidden="true" />
                    </Button>
                  )}
                  {!r.valid_to && (
                    <Button variant="ghost" size="icon-sm" aria-label={`Regel ${r.account_text} beenden`} onClick={() => setEnd(r)}>
                      <XIcon aria-hidden="true" />
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
      {visible.length === 0 && <p className="text-sm text-muted-foreground">Keine Regeln.</p>}

      {edit && <RuleDialog year={year} rule={edit === 'new' ? null : edit} items={items} itemLabel={itemLabel} onClose={() => setEdit(null)} />}
      {end && (
        <ConfirmDialog
          title="Regel beenden"
          confirmLabel="Beenden"
          pendingLabel="Wird beendet …"
          pending={action.pending}
          error={action.error}
          destructive
          onClose={() => setEnd(null)}
          onConfirm={async () => {
            const res = await action.run('fi_budget_rule_end', { p_rule: end.id, p_comment: null })
            if (res) {
              toast.success(`Regel ${end.account_text} beendet.`)
              setEnd(null)
            }
          }}
        >
          Buchungen auf {end.account_text} zählen danach nach der nächsten passenden Regel. Die Regel bleibt im Verlauf.
        </ConfirmDialog>
      )}
      {csvRows && (
        <ConfirmDialog
          title="zuordnung.csv übernehmen"
          confirmLabel="Übernehmen"
          pendingLabel="Wird übernommen …"
          pending={action.pending}
          error={action.error}
          onClose={() => setCsvRows(null)}
          onConfirm={importCsv}
        >
          {csvRows.length} Zeilen. Alle gültigen Regeln für {year} werden durch die Datei ersetzt; Gesamtbudgets werden wie in der Datei
          gebildet. Bei Fehlern wird nichts übernommen.
        </ConfirmDialog>
      )}
    </div>
  )
}

function RuleDialog({ year, rule, items, itemLabel, onClose }: { year: number; rule: RuleRow | null; items: ItemRow[]; itemLabel: Map<string, string>; onClose: () => void }) {
  const [account, setAccount] = useState(rule?.account_text ?? '')
  const [costCenters, setCostCenters] = useState(rule?.cost_centers.join(', ') ?? '')
  const [item, setItem] = useState(rule?.item_id ?? '')
  const [status, setStatus] = useState<string>(rule?.status ?? 'ok')
  const [note, setNote] = useState(rule?.note ?? '')
  const [label, setLabel] = useState(rule?.account_label ?? '')
  const [comment, setComment] = useState('')
  const action = useAction()

  async function save() {
    if (account.trim() === '') return action.setError('Bitte eine Kontoangabe eingeben.')
    const res = await action.run('fi_budget_rule_save', {
      p_rule: {
        id: rule?.id ?? null,
        year,
        account_text: account,
        cost_centers: costCenters.split(/[,/]/).map((c) => c.trim()).filter(Boolean),
        item_id: item || null,
        status,
        note,
        account_label: label,
      },
      p_comment: comment,
    })
    if (res) {
      toast.success('Regel gespeichert.')
      onClose()
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !action.pending && onClose()}>
      <DialogContent className="sm:max-w-lg">
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault()
            save()
          }}
        >
          <DialogHeader>
            <DialogTitle>{rule ? 'Regel ändern' : 'Neue Regel'}</DialogTitle>
            <DialogDescription>Änderungen gelten ab sofort für alle Buchungen des Jahres {year}; die alte Regel bleibt im Verlauf.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="rule-account">Kontoangabe</Label>
              <Input id="rule-account" value={account} onChange={(e) => setAccount(e.target.value)} placeholder="6326 3, 6326 oder 4000-7999" />
            </div>
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="rule-cc">Kostenstelle (optional)</Label>
              <Input id="rule-cc" value={costCenters} onChange={(e) => setCostCenters(e.target.value)} placeholder="z. B. 1, 3" />
            </div>
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="rule-label">Kontobezeichnung (optional)</Label>
            <Input id="rule-label" value={label} onChange={(e) => setLabel(e.target.value)} />
          </div>
          <div className="grid gap-3 sm:grid-cols-[1fr_auto]">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="rule-item">Budgetposten</Label>
              <select id="rule-item" className={selectClassName + ' sm:max-w-none'} value={item} onChange={(e) => setItem(e.target.value)}>
                <option value="">ohne Budgetposten (nicht zugeordnet)</option>
                {items.map((i) => (
                  <option key={i.id} value={i.id}>
                    {itemLabel.get(i.id)}
                    {i.kind === 'income' ? ' (Einnahme)' : ''}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="rule-status">Status</Label>
              <select id="rule-status" className={selectClassName} value={status} onChange={(e) => setStatus(e.target.value)}>
                {Object.entries(RULE_STATUS).map(([k, v]) => (
                  <option key={k} value={k}>
                    {v}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="rule-note">Hinweis (optional)</Label>
            <textarea id="rule-note" className={textareaClassName} value={note} maxLength={500} onChange={(e) => setNote(e.target.value)} />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="rule-comment">Kommentar zur Änderung (optional)</Label>
            <Input id="rule-comment" value={comment} onChange={(e) => setComment(e.target.value)} />
          </div>
          <FormError text={action.error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={action.pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={action.pending}>
              {action.pending ? 'Wird gespeichert …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
