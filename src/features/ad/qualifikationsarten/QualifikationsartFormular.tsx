import { useState, type FormEvent } from 'react'
import { ChevronLeftIcon, CircleAlertIcon, InfoIcon } from 'lucide-react'
import { Link, useLoaderData, useLocation, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  KIND_LABELS,
  KINDS,
  LEVEL_LABELS,
  LEVELS,
  saveQualificationType,
  STATUS_LABELS,
  validityRule,
  type EditResult,
  type LicenseLevel,
  type QualificationKind,
  type QualificationStatus,
  type SaveInput,
} from '@/features/ad/qualifikationsarten/data'
import { StatusBadge } from '@/features/ad/qualifikationsarten/QualifikationsartenListe'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDateTime } from '@/lib/format'

const VALIDITY_CHANGED = 'Die Änderung gilt für neue Einträge. Vorhandene Ablaufdaten bleiben unverändert.'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm'

// T078 (US-AD-17 AK2–AK5): Qualifikationsart anlegen (/neu) oder ansehen und ändern (/:id); R21–R26.
export function QualifikationsartFormular({ basePath = '/ad/qualifikationsarten' }: { basePath?: string }) {
  const data = useLoaderData() as EditResult
  const location = useLocation()
  const info = (location.state as { info?: string } | null)?.info ?? null

  if (data.failed) {
    return (
      <section className="flex flex-col gap-4">
        <BackLink basePath={basePath} />
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {MESSAGES.unexpected}
        </p>
      </section>
    )
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <BackLink basePath={basePath} />
        <h1 className="flex flex-wrap items-center gap-3 text-xl font-semibold">
          {data.item ? (data.item.code ? `${data.item.code} – ${data.item.name}` : data.item.name) : 'Neue Qualifikationsart'}
          {data.item && <StatusBadge status={data.item.status} />}
        </h1>
        {data.item && (
          <p className="text-sm text-muted-foreground">
            {data.usage !== null && <>Verwendet bei {data.usage === 1 ? '1 Person' : `${data.usage} Personen`}</>}
            {data.usage !== null && data.item.updated_at && ' · '}
            {data.item.updated_at && (
              <>
                geändert am {formatDateTime(data.item.updated_at)}
                {data.updatedByName && ` von ${data.updatedByName}`}
              </>
            )}
          </p>
        )}
        {info && (
          <p role="status" className="flex items-center gap-2 text-sm">
            <InfoIcon aria-hidden="true" className="size-4 shrink-0 text-primary" />
            {info}
          </p>
        )}
      </div>

      {data.canEdit ? (
        <Form key={data.item?.id ?? 'neu'} data={data} basePath={basePath} />
      ) : (
        <ReadOnly data={data} />
      )}
    </section>
  )
}

function BackLink({ basePath }: { basePath: string }) {
  return (
    <Link
      to={basePath}
      className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
    >
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Qualifikationsarten
    </Link>
  )
}

function dosbLabel(value: boolean | null) {
  return value === null ? 'nicht bekannt' : value ? 'ja' : 'nein'
}

function ReadOnly({ data }: { data: EditResult }) {
  const i = data.item!
  const rows: [string, React.ReactNode][] = [
    ['Bezeichnung', i.name],
    ['Kürzel', i.code ?? '–'],
    ['Sparte', i.discipline],
    ['Typ', KIND_LABELS[i.kind]],
    ['Lizenzstufe', i.level ? LEVEL_LABELS[i.level] : '–'],
    ['Spezifikation', i.specification ?? '–'],
    ['Aussteller', i.issuer],
    ['DOSB-lizenzfähig', dosbLabel(i.dosb_eligible)],
    ['Gültigkeitsdauer', i.validity_years ? `${i.validity_years} Jahre` : '–'],
    ['Status', STATUS_LABELS[i.status]],
    ['Hinweis', i.note ?? '–'],
    ['Quell-ID', i.source_ref ?? '–'],
  ]
  return (
    <dl className="grid max-w-xl gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
      {rows.map(([label, value]) => (
        <div key={label} className="contents">
          <dt className="text-muted-foreground">{label}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  )
}

function Form({ data, basePath }: { data: EditResult; basePath: string }) {
  const navigate = useNavigate()
  const item = data.item
  const [input, setInput] = useState<SaveInput>({
    code: item?.code ?? '',
    name: item?.name ?? '',
    discipline: item?.discipline ?? '',
    kind: item?.kind ?? 'license',
    level: item?.level ?? '',
    specification: item?.specification ?? '',
    issuer: item?.issuer ?? 'Bundesverband',
    dosb_eligible: item?.dosb_eligible === null || item === null ? '' : item.dosb_eligible ? 'true' : 'false',
    validity_years: item?.validity_years?.toString() ?? '',
    status: item?.status ?? 'current',
    note: item?.note ?? '',
  })
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  const rule = validityRule(input.kind)
  const set = <K extends keyof SaveInput>(key: K, value: SaveInput[K]) => setInput((c) => ({ ...c, [key]: value }))

  const fieldErrors: Partial<Record<'name' | 'code' | 'level' | 'validity', true>> = {}
  if (error === MESSAGES.qualificationNameRequired || error === MESSAGES.qualificationNameTaken) fieldErrors.name = true
  if (error === MESSAGES.qualificationCodeTaken || error === MESSAGES.qualificationCodeFormat) fieldErrors.code = true
  if (error === MESSAGES.qualificationLevelRequired) fieldErrors.level = true
  if (error === MESSAGES.qualificationValidity) fieldErrors.validity = true

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    // R21, R23, R24 vorab im Frontend; die Datenbank prüft erneut
    if (!input.name.trim()) return setError(MESSAGES.qualificationNameRequired)
    if (input.kind === 'license' && !input.level) return setError(MESSAGES.qualificationLevelRequired)
    const validity = input.validity_years.trim()
    if (rule !== 'hidden' && validity !== '' && !/^(10|[1-9])$/.test(validity)) return setError(MESSAGES.qualificationValidity)
    if (rule === 'required' && validity === '') return setError(MESSAGES.qualificationValidity)

    setPending(true)
    try {
      const result = await saveQualificationType(item?.id ?? null, input)
      if (result.error) {
        setError(toMessage(result.error).text)
        return
      }
      // R26: Hinweis nach geänderter Gültigkeitsdauer
      const validityChanged = item !== null && (item.validity_years?.toString() ?? '') !== (rule === 'hidden' ? '' : validity)
      navigate(`${basePath}/${result.id}`, { replace: true, state: validityChanged ? { info: VALIDITY_CHANGED } : null })
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  return (
    <form className="flex max-w-xl flex-col gap-6" onSubmit={onSubmit} noValidate>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Bezeichnung" htmlFor="qt-name" className="sm:col-span-2" invalid={fieldErrors.name}>
          <Input id="qt-name" value={input.name} onChange={(e) => set('name', e.target.value)} required aria-invalid={fieldErrors.name} autoComplete="off" />
        </Field>
        <Field label="Kürzel" hint="optional, Großbuchstaben und Ziffern" htmlFor="qt-code" invalid={fieldErrors.code}>
          <Input id="qt-code" value={input.code} onChange={(e) => set('code', e.target.value)} maxLength={10} aria-invalid={fieldErrors.code} autoComplete="off" className="uppercase" />
        </Field>
        <Field label="Sparte" htmlFor="qt-discipline">
          <Input id="qt-discipline" list="qt-disciplines" value={input.discipline} onChange={(e) => set('discipline', e.target.value)} required autoComplete="off" />
          <datalist id="qt-disciplines">
            {data.disciplines.map((d) => (
              <option key={d} value={d} />
            ))}
          </datalist>
        </Field>
        <Field label="Typ" htmlFor="qt-kind">
          <select id="qt-kind" value={input.kind} onChange={(e) => set('kind', e.target.value as QualificationKind)} className={selectClassName}>
            {KINDS.map((k) => (
              <option key={k} value={k}>
                {KIND_LABELS[k]}
              </option>
            ))}
          </select>
        </Field>
        {input.kind === 'license' && (
          <Field label="Lizenzstufe" htmlFor="qt-level" invalid={fieldErrors.level}>
            <select id="qt-level" value={input.level} onChange={(e) => set('level', e.target.value as LicenseLevel | '')} aria-invalid={fieldErrors.level} className={selectClassName}>
              <option value="">– bitte wählen –</option>
              {LEVELS.map((l) => (
                <option key={l} value={l}>
                  {LEVEL_LABELS[l]}
                </option>
              ))}
            </select>
          </Field>
        )}
        <Field label="Spezifikation" hint="optional" htmlFor="qt-specification">
          <Input id="qt-specification" value={input.specification} onChange={(e) => set('specification', e.target.value)} autoComplete="off" />
        </Field>
        <Field label="Aussteller" htmlFor="qt-issuer">
          <Input id="qt-issuer" list="qt-issuers" value={input.issuer} onChange={(e) => set('issuer', e.target.value)} required autoComplete="off" />
          <datalist id="qt-issuers">
            {data.issuers.map((d) => (
              <option key={d} value={d} />
            ))}
          </datalist>
        </Field>
        <Field label="DOSB-lizenzfähig" htmlFor="qt-dosb">
          <select id="qt-dosb" value={input.dosb_eligible} onChange={(e) => set('dosb_eligible', e.target.value as SaveInput['dosb_eligible'])} className={selectClassName}>
            <option value="">nicht bekannt</option>
            <option value="true">ja</option>
            <option value="false">nein</option>
          </select>
        </Field>
        {rule !== 'hidden' && (
          <Field
            label="Gültigkeitsdauer in Jahren"
            hint={rule === 'optional' ? 'optional, 1–10' : '1–10'}
            htmlFor="qt-validity"
            invalid={fieldErrors.validity}
          >
            <Input
              id="qt-validity"
              type="number"
              inputMode="numeric"
              min={1}
              max={10}
              step={1}
              value={input.validity_years}
              onChange={(e) => set('validity_years', e.target.value)}
              required={rule === 'required'}
              aria-invalid={fieldErrors.validity}
            />
          </Field>
        )}
        <Field label="Status" htmlFor="qt-status">
          <select id="qt-status" value={input.status} onChange={(e) => set('status', e.target.value as QualificationStatus)} className={selectClassName}>
            {(Object.keys(STATUS_LABELS) as QualificationStatus[]).map((s) => (
              <option key={s} value={s}>
                {STATUS_LABELS[s]}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Hinweis" hint="optional" htmlFor="qt-note" className="sm:col-span-2">
          <Input id="qt-note" value={input.note} onChange={(e) => set('note', e.target.value)} autoComplete="off" />
        </Field>
        {item?.source_ref && (
          <Field label="Quell-ID" hint="nur lesen" htmlFor="qt-source">
            <Input id="qt-source" value={item.source_ref} readOnly />
          </Field>
        )}
      </div>

      {error && (
        <p id="qt-error" role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Speichern …' : 'Speichern'}
        </Button>
        <Button variant="outline" asChild>
          <Link to={item ? `${basePath}/${item.id}` : basePath}>Abbrechen</Link>
        </Button>
      </div>
    </form>
  )
}

function Field({
  label,
  hint,
  htmlFor,
  invalid,
  className,
  children,
}: {
  label: string
  hint?: string
  htmlFor: string
  invalid?: boolean
  className?: string
  children: React.ReactNode
}) {
  return (
    <div className={['flex flex-col gap-2', className].filter(Boolean).join(' ')}>
      <Label htmlFor={htmlFor} className={invalid ? 'text-destructive' : undefined}>
        {label}
        {hint && <span className="font-normal text-muted-foreground"> ({hint})</span>}
      </Label>
      {children}
    </div>
  )
}
