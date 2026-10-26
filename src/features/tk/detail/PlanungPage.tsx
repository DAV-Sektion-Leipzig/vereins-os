import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { SaveIcon } from 'lucide-react'
import { useLoaderData, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { AusgabenTab } from '@/features/tk/ausgaben/AusgabenTab'
import type { TextInput } from '@/features/tk/ausgaben/texts'
import { FormDialog } from '@/features/fi/shared/FormDialog'
import { LoadFailed } from '@/features/gr/shared/ui'
import { calculate, calcInput, savePayload, toDraft, type DetailResult, type Draft, type SaveResult } from '@/features/tk/detail/data'
import { NeueLeitungDialog } from '@/features/tk/detail/NeueLeitungDialog'
import { Seitenleiste } from '@/features/tk/detail/Seitenleiste'
import { Step1, Step2, Step3, Step4, Step5, Step6, Step7, type StepProps } from '@/features/tk/detail/steps'
import { Verlauf } from '@/features/tk/detail/Verlauf'
import { TK_MESSAGES, type TkError } from '@/features/tk/errors'
import { missingLabel, PLAN_TYPE_LABELS, STEPS, stepOf } from '@/features/tk/labels'
import { formatSpan } from '@/features/tk/liste/data'
import { tkRpc } from '@/features/tk/rpc'
import { StatusBadge, textareaClassName } from '@/features/tk/shared'
import type { PlanDetail, PlanFields } from '@/features/tk/types'
import { formatTime, todayIso } from '@/lib/format'
import { cn } from '@/lib/utils'

const AUTOSAVE_MS = 2000

type Action = 'submit' | 'query' | 'resubmit' | 'approve' | 'publish' | 'cancel' | 'done' | 'close' | 'delete'

const ACTIONS: Record<Action, { label: string; title: string; pending: string; done: string; input?: 'comment' | 'reason' | 'optional' | 'yolawo'; destructive?: boolean }> = {
  submit: { label: 'Einreichen', title: 'Planung einreichen', pending: 'Wird eingereicht …', done: 'Planung eingereicht.' },
  query: { label: 'Rückfrage', title: 'Rückfrage stellen', pending: 'Wird gesendet …', done: 'Rückfrage gestellt.', input: 'comment' },
  resubmit: { label: 'Erneut einreichen', title: 'Erneut einreichen', pending: 'Wird eingereicht …', done: 'Planung erneut eingereicht.' },
  approve: { label: 'Freigeben', title: 'Planung freigeben', pending: 'Wird freigegeben …', done: 'Planung freigegeben.', input: 'optional' },
  publish: { label: 'In Yolawo angelegt', title: 'In Yolawo angelegt', pending: 'Wird gespeichert …', done: 'In Yolawo angelegt; der Einsatz ist in der Anwesenheitserfassung.', input: 'yolawo' },
  cancel: { label: 'Absagen', title: 'Planung absagen', pending: 'Wird abgesagt …', done: 'Planung abgesagt.', input: 'reason', destructive: true },
  done: { label: 'Durchgeführt', title: 'Als durchgeführt markieren', pending: 'Wird gespeichert …', done: 'Als durchgeführt markiert.' },
  close: { label: 'Abschließen', title: 'Planung abschließen', pending: 'Wird abgeschlossen …', done: 'Planung abgeschlossen.' },
  delete: { label: 'Löschen', title: 'Planung löschen', pending: 'Wird gelöscht …', done: 'Planung gelöscht.', destructive: true },
}

/** Statusaktionen je Status und Recht (spec.md TK 4; A11). */
function availableActions(d: PlanDetail): Action[] {
  const s = d.plan.status
  const w = d.can_change_status
  const list: Action[] = []
  if (s === 'draft' && w) list.push('submit')
  if (s === 'submitted' && d.can_approve) list.push('approve')
  if (s === 'submitted' && w) list.push('query')
  if (s === 'query' && w) list.push('resubmit')
  if (s === 'approved' && (d.can_approve || d.can_manage)) list.push('publish')
  if (s === 'published' && w && d.plan.end_date && d.plan.end_date < todayIso()) list.push('done')
  if (s === 'done' && d.can_manage) list.push('close')
  if (['draft', 'submitted', 'query', 'approved', 'published'].includes(s) && w) list.push('cancel')
  if (d.can_manage && (s === 'draft' || (s === 'cancelled' && !d.plan.ez_event_id))) list.push('delete')
  return list
}

// T019 (US-TK-03 bis -14, -16 bis -18): Planung mit Schritten 1–7, Seitenleiste, Speichern mit row_version und
// Autospeichern 2 s nach der letzten Änderung (kein Entwurf im Browser-Speicher), Konflikt (R20), Statusdialoge, Verlauf.
export function PlanungPage() {
  const { detail, error } = useLoaderData() as DetailResult
  if (!detail) {
    if (error?.code === 'TK_NOT_FOUND') return <p className="text-sm text-muted-foreground">{TK_MESSAGES.notFound}</p>
    return <LoadFailed text={error?.text} />
  }
  return <PlanEditor key={detail.plan.id} initial={detail} />
}

function PlanEditor({ initial }: { initial: PlanDetail }) {
  const navigate = useNavigate()
  const [detail, setDetail] = useState(initial)
  const [draft, setDraftState] = useState<Draft>(() => toDraft(initial))
  const [dirty, setDirty] = useState(false)
  const [saving, setSaving] = useState(false)
  const [savedAt, setSavedAt] = useState<Date | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [conflict, setConflict] = useState<string | null>(null)
  const [step, setStep] = useState<number | 'verlauf' | 'ausgaben'>(1)
  const [newPerson, setNewPerson] = useState(false)
  const [action, setAction] = useState<Action | null>(null)
  const [input, setInput] = useState('')
  const [actionError, setActionError] = useState<TkError | null>(null)
  const [actionPending, setActionPending] = useState(false)
  const editSeq = useRef(0)
  const savingRef = useRef(false)
  const rowVersion = useRef(initial.plan.row_version)

  const planId = detail.plan.id
  const canWrite = detail.can_write
  const calc = useMemo(() => calculate(calcInput(draft), detail.rates), [draft, detail.rates])
  const missing = useMemo(() => new Set(detail.results?.missing ?? []), [detail.results])

  const reload = useCallback(async (replaceDraft: boolean) => {
    const res = await tkRpc<PlanDetail>('tk_get_plan', { p_id: planId })
    if (res.error) return false
    setDetail(res.data)
    rowVersion.current = res.data.plan.row_version
    if (replaceDraft) {
      setDraftState(toDraft(res.data))
      setDirty(false)
    } else {
      // Satzart der Leitung aus der Datenbank übernehmen, Eingaben behalten
      const byPerson = new Map(res.data.leaders.map((l) => [l.person_id, l]))
      setDraftState((d) => ({ ...d, leaders: d.leaders.map((l) => ({ ...l, ...pickLicense(byPerson.get(l.person_id)) })) }))
    }
    return true
  }, [planId])

  const save = useCallback(async (): Promise<boolean> => {
    if (savingRef.current || !canWrite || conflict) return false
    savingRef.current = true
    setSaving(true)
    const seq = editSeq.current
    const res = await tkRpc<SaveResult>('tk_save_plan', savePayload(planId, draft, rowVersion.current, detail.can_read_contacts))
    savingRef.current = false
    setSaving(false)
    if (res.error) {
      if (res.error.code === 'TK_CONFLICT') setConflict(res.error.text)
      else setSaveError(res.error.text)
      return false
    }
    setSaveError(null)
    rowVersion.current = res.data.row_version
    if (res.data.warning === 'TK_EZ_LOCKED') toast.warning(TK_MESSAGES.ezLocked)
    if (res.data.warning === 'TK_EZ_SYNC_FAILED') toast.warning(TK_MESSAGES.ezSyncFailed)
    setSavedAt(new Date())
    await reload(editSeq.current === seq)
    return true
  }, [canWrite, conflict, detail.can_read_contacts, draft, planId, reload])

  // Autospeichern 2 s nach der letzten Änderung, solange die Planung bearbeitbar ist
  useEffect(() => {
    if (!dirty || !canWrite || conflict) return
    const timer = window.setTimeout(() => void save(), AUTOSAVE_MS)
    return () => window.clearTimeout(timer)
  }, [dirty, draft, canWrite, conflict, save])

  // Warnung beim Verlassen mit ungespeicherten Eingaben
  useEffect(() => {
    if (!dirty) return
    const handler = (e: BeforeUnloadEvent) => e.preventDefault()
    window.addEventListener('beforeunload', handler)
    return () => window.removeEventListener('beforeunload', handler)
  }, [dirty])

  function setFields(patch: Partial<PlanFields>) {
    editSeq.current += 1
    setDirty(true)
    setDraftState((d) => ({ ...d, fields: { ...d.fields, ...patch } }))
  }
  function setDraft(fn: (d: Draft) => Draft) {
    editSeq.current += 1
    setDirty(true)
    setDraftState(fn)
  }

  async function runAction() {
    if (!action) return
    setActionPending(true)
    setActionError(null)
    if (dirty && canWrite && !(await save())) {
      setActionPending(false)
      return setActionError({ code: 'SAVE', details: '', text: TK_MESSAGES.saveFailed })
    }
    if (action === 'delete') {
      const res = await tkRpc('tk_delete_plan', { p_id: planId })
      setActionPending(false)
      if (res.error) return setActionError(res.error)
      toast.success(ACTIONS.delete.done)
      return navigate('/tk')
    }
    const res = await tkRpc(
      'tk_change_status',
      {
        p_id: planId,
        p_action: action,
        p_comment: ACTIONS[action].input && ACTIONS[action].input !== 'yolawo' ? input.trim() || null : null,
        p_yolawo_ref: action === 'publish' ? input.trim() || null : null,
        p_row_version: rowVersion.current,
      },
      action,
    )
    setActionPending(false)
    if (res.error) {
      if (res.error.missing?.length) setStep(stepOf(res.error.missing[0]))
      if (res.error.code === 'TK_CONFLICT') setConflict(res.error.text)
      return setActionError(res.error)
    }
    toast.success(ACTIONS[action].done)
    setAction(null)
    setInput('')
    await reload(true)
  }

  const actions = availableActions(detail)
  const stepProps: StepProps = { draft, detail, calc, rates: detail.rates, disabled: !canWrite, missing, setFields, setDraft }
  const rateLabel = (k: string) => detail.rates[k]?.label
  const textInput: TextInput = {
    fields: draft.fields,
    leaders: draft.leaders,
    leaderIds: draft.leaders.map((l) => l.person_id),
    contacts: detail.can_read_contacts && !detail.plan.contacts_purged_at ? draft.contacts : undefined,
    legs: draft.legs,
    costs: draft.costs.filter((c) => c.label.trim() !== ''),
    calc,
    co2Price: detail.rates.rCO2?.value != null ? Number(detail.rates.rCO2.value) : null,
    efs: Object.fromEntries(Object.entries(detail.rates).filter(([k]) => k.startsWith('ef_')).map(([k, r]) => [k, Number(r.value ?? 0)])),
    missing: detail.results?.missing ?? [],
    today: todayIso(),
  }

  return (
    <div className="flex flex-col gap-6">
      <header className="flex flex-col gap-3">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="flex flex-col gap-1">
            <h1 className="text-2xl font-semibold tracking-tight">{draft.fields.title || 'Ohne Titel'}</h1>
            <p className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
              <StatusBadge status={detail.plan.status} />
              <span>{PLAN_TYPE_LABELS[draft.fields.plan_type]}</span>·<span>Referat {detail.plan.referat_name}</span>·
              <span className="tabular-nums">{formatSpan(draft.fields.start_date, draft.fields.end_date)}</span>
              {detail.plan.yolawo_ref && <span>· Yolawo {detail.plan.yolawo_ref}</span>}
            </p>
            {detail.plan.cancel_reason && <p className="text-sm">Abgesagt: {detail.plan.cancel_reason}</p>}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {canWrite && (
              <>
                <span className="text-xs text-muted-foreground" aria-live="polite">
                  {saving ? 'Wird gespeichert …' : dirty ? 'Nicht gespeichert' : savedAt ? `Gespeichert ${formatTime(savedAt)} Uhr` : ''}
                </span>
                <Button variant="outline" onClick={() => void save()} disabled={saving || !dirty || !!conflict}>
                  <SaveIcon data-icon="inline-start" aria-hidden="true" />
                  Speichern
                </Button>
              </>
            )}
            {actions.map((a) => (
              <Button key={a} variant={ACTIONS[a].destructive ? 'outline' : 'default'} onClick={() => { setAction(a); setInput(''); setActionError(null) }}>
                {ACTIONS[a].label}
              </Button>
            ))}
          </div>
        </div>
        {saveError && <p role="alert" className="text-sm text-destructive">{saveError}</p>}
        {!canWrite && detail.plan.status !== 'draft' && (
          <p className="text-sm text-muted-foreground">
            {['done', 'closed', 'cancelled'].includes(detail.plan.status) ? TK_MESSAGES.lockedFinal : ['approved', 'published'].includes(detail.plan.status) && detail.can_change_status ? TK_MESSAGES.lockedApproved : 'Nur lesen.'}
          </p>
        )}
      </header>

      <nav aria-label="Schritte" className="-mx-1 overflow-x-auto">
        <ul className="flex gap-1 px-1">
          {[...STEPS.map((s) => ({ key: s.n as number | 'verlauf' | 'ausgaben', label: `${s.n}. ${s.title}`, open: (detail.results?.missing ?? []).filter((m) => stepOf(m) === s.n).length })),
            { key: 'ausgaben' as const, label: 'Ausgaben', open: 0 }, { key: 'verlauf' as const, label: 'Verlauf', open: 0 }].map((t) => (
            <li key={t.key}>
              <button
                type="button"
                onClick={() => setStep(t.key)}
                aria-current={step === t.key ? 'step' : undefined}
                className={cn('inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-sm whitespace-nowrap', step === t.key ? 'bg-accent font-medium text-accent-foreground' : 'hover:bg-muted')}
              >
                {t.label}
                {t.open > 0 && <span className="rounded-full bg-destructive/10 px-1.5 text-xs text-destructive">{t.open}</span>}
              </button>
            </li>
          ))}
        </ul>
      </nav>

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_20rem]">
        <main className="min-w-0">
          {step === 1 && <Step1 {...stepProps} onNewPerson={() => setNewPerson(true)} />}
          {step === 2 && <Step2 {...stepProps} />}
          {step === 3 && <Step3 {...stepProps} />}
          {step === 4 && <Step4 {...stepProps} />}
          {step === 5 && <Step5 {...stepProps} />}
          {step === 6 && <Step6 {...stepProps} />}
          {step === 7 && <Step7 {...stepProps} />}
          {step === 'ausgaben' && <AusgabenTab input={textInput} missingLabels={(detail.results?.missing ?? []).map((m) => missingLabel(m, rateLabel))} />}
          {step === 'verlauf' && <Verlauf entries={detail.history} />}
          {typeof step === 'number' && (
            <div className="mt-8 flex justify-between gap-3">
              <Button variant="outline" disabled={step === 1} onClick={() => setStep(step - 1)}>
                Zurück
              </Button>
              <Button variant="outline" disabled={step === 7} onClick={() => setStep(step + 1)}>
                Weiter
              </Button>
            </div>
          )}
        </main>
        <Seitenleiste planType={draft.fields.plan_type} calc={calc} results={detail.results} rates={detail.rates}
          minParticipants={draft.fields.min_participants} onStep={setStep} />
      </div>

      {newPerson && (
        <NeueLeitungDialog
          planId={planId}
          presentIds={draft.leaders.map((l) => l.person_id)}
          onClose={() => setNewPerson(false)}
          onAdd={(personId, name) => {
            setNewPerson(false)
            setDraft((d) => d.leaders.some((l) => l.person_id === personId) ? d : {
              ...d,
              leaders: [...d.leaders, { person_id: personId, name, role: d.leaders.some((l) => l.role === 'lead') ? 'co_lead' : 'lead', rate_kind: null, license_name: null, license_valid_from: null, license_valid_until: null }],
            })
          }}
        />
      )}

      {conflict && (
        <ConfirmDialog title="Planung geändert" confirmLabel="Neu laden" pendingLabel="Wird geladen …" pending={false} error={null}
          onConfirm={async () => { setConflict(null); await reload(true) }} onClose={() => setConflict(null)}>
          {conflict}
        </ConfirmDialog>
      )}

      {action && !ACTIONS[action].input && (
        <ConfirmDialog title={ACTIONS[action].title} confirmLabel={ACTIONS[action].label} pendingLabel={ACTIONS[action].pending}
          pending={actionPending} error={actionError ? actionText(actionError, rateLabel) : null} destructive={ACTIONS[action].destructive}
          onConfirm={runAction} onClose={() => setAction(null)}>
          {action === 'delete' ? 'Die Planung wird endgültig gelöscht.' : action === 'close' ? 'Danach kann niemand die Planung mehr ändern.' : null}
        </ConfirmDialog>
      )}
      {action && ACTIONS[action].input && (
        <FormDialog title={ACTIONS[action].title} submitLabel={ACTIONS[action].label} pendingLabel={ACTIONS[action].pending}
          pending={actionPending} error={actionError ? actionText(actionError, rateLabel) : null} destructive={ACTIONS[action].destructive}
          onSubmit={runAction} onClose={() => setAction(null)}
          description={action === 'publish' ? 'Legt den Einsatz in der Anwesenheitserfassung an.' : action === 'cancel' && detail.plan.ez_event_id ? 'Der Einsatz in der Anwesenheitserfassung wird als abgesagt markiert.' : undefined}>
          {ACTIONS[action].input === 'yolawo' ? (
            <div className="flex flex-col gap-2">
              <Label htmlFor="tk-action-input">Link oder Nummer des Angebots (optional)</Label>
              <Input id="tk-action-input" value={input} maxLength={200} onChange={(e) => setInput(e.target.value)} autoComplete="off" />
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              <Label htmlFor="tk-action-input">
                {ACTIONS[action].input === 'reason' ? 'Grund' : ACTIONS[action].input === 'comment' ? 'Rückfrage' : 'Kommentar (optional)'}
              </Label>
              <textarea id="tk-action-input" className={textareaClassName} value={input} maxLength={500} onChange={(e) => setInput(e.target.value)} />
            </div>
          )}
        </FormDialog>
      )}
    </div>
  )
}

function pickLicense(l: PlanDetail['leaders'][number] | undefined) {
  if (!l) return {}
  return { rate_kind: l.rate_kind, license_name: l.license_name, license_valid_from: l.license_valid_from, license_valid_until: l.license_valid_until }
}

function actionText(error: TkError, rateLabel: (k: string) => string | undefined): string {
  if (!error.missing?.length) return error.text
  return `${error.text} ${error.missing.map((m) => missingLabel(m, rateLabel)).join(', ')}.`
}
