import { useEffect, useRef, useState, type FormEvent } from 'react'
import { ChevronLeftIcon, CircleAlertIcon } from 'lucide-react'
import { Link, useLoaderData, useLocation, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAdAccess } from '@/features/ad/access'
import {
  allowsApprove,
  allowsReferat,
  personCountLabel,
  saveTemplate,
  type EditData,
  type Module,
  type Right,
  type Rights,
} from '@/features/ad/rechtevorlagen/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { LEVEL_LABELS, LEVELS, SCOPE_LABELS, SCOPES, type Level, type Scope } from '@/lib/rights'

const NONE: Right = { level: 'none', scope: 'all', approve: false }

/** Anzeige einer Stufe, bei Reichweite „Referat“ mit Zusatz (US-AD-20 AK1). */
function rightLabel(right: Right) {
  if (right.level === 'none') return LEVEL_LABELS.none
  const level = right.approve ? `${LEVEL_LABELS[right.level]} + freigeben` : LEVEL_LABELS[right.level]
  return right.scope === 'referat' ? `${level}, Reichweite Referat` : level
}

function BackLink() {
  return (
    <Link
      to="/ad/rechtevorlagen"
      className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
    >
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Rechtevorlagen
    </Link>
  )
}

// T069 (US-AD-10, US-AD-20): Vorlage anlegen (/ad/rechtevorlagen/neu) oder ansehen und ändern (/:id).
export function RechtevorlageBearbeiten() {
  const data = useLoaderData() as EditData
  const { canEdit } = useAdAccess()

  if (data.failed) {
    return (
      <section className="flex flex-col gap-4">
        <BackLink />
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {MESSAGES.unexpected}
        </p>
      </section>
    )
  }

  if (!canEdit && data.template) return <ReadOnlyTemplate data={data} />
  return <TemplateForm key={data.template?.id ?? 'neu'} data={data} />
}

function ReadOnlyTemplate({ data }: { data: EditData }) {
  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <BackLink />
        <h1 className="text-xl font-semibold">{data.template!.name}</h1>
        {data.template!.description && <p className="text-sm text-muted-foreground">{data.template!.description}</p>}
        <p className="text-sm text-muted-foreground tabular-nums">{personCountLabel(data.personCount)}</p>
      </div>
      <section aria-labelledby="rights-heading" className="flex flex-col gap-3">
        <h2 id="rights-heading" className="font-medium">
          Rechte je Modul
        </h2>
        <dl className="max-w-xl divide-y rounded-xl border">
          {data.modules.map((m) => (
            <div key={m.code} className="flex items-center justify-between gap-4 px-4 py-2.5 text-sm">
              <dt>{m.name}</dt>
              <dd
                className={(data.rights[m.code] ?? NONE).level === 'none' ? 'text-right text-muted-foreground' : 'text-right font-medium'}
              >
                {rightLabel(data.rights[m.code] ?? NONE)}
              </dd>
            </div>
          ))}
        </dl>
      </section>
    </section>
  )
}

function TemplateForm({ data }: { data: EditData }) {
  const navigate = useNavigate()
  const location = useLocation()
  const [name, setName] = useState(data.template?.name ?? '')
  const [description, setDescription] = useState(data.template?.description ?? '')
  const [rights, setRights] = useState<Rights>(data.rights)
  const [error, setError] = useState<string | null>((location.state as { error?: string } | null)?.error ?? null)
  const [pending, setPending] = useState(false)

  const isNew = !data.template
  // Doppelter Name gehört zum Feld „Name“, alle anderen Fehler stehen über den Knöpfen
  const nameTaken = error === MESSAGES.templateNameTaken
  const nameRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (nameTaken) nameRef.current?.focus()
  }, [nameTaken])

  function setLevel(code: string, level: Level) {
    // „darf freigeben“ gibt es nur mit einer Stufe (R50)
    setRights((current) => {
      const right = current[code] ?? NONE
      return { ...current, [code]: { ...right, level, approve: level === 'none' ? false : right.approve } }
    })
  }

  function setApprove(code: string, approve: boolean) {
    setRights((current) => ({ ...current, [code]: { ...(current[code] ?? NONE), approve } }))
  }

  function setScope(code: string, scope: Scope) {
    setRights((current) => ({ ...current, [code]: { ...(current[code] ?? NONE), scope } }))
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!name.trim()) return
    setError(null)
    setPending(true)
    try {
      const existing = data.template ? { id: data.template.id, rights: data.rights } : null
      const result = await saveTemplate(existing, { name, description, rights })
      if (result.error) {
        const text = toMessage(result.error).text
        // Neue Vorlage ist angelegt, aber Stufen fehlen: zur Vorlage wechseln, damit erneut gespeichert werden kann
        if (isNew && result.id) navigate(`/ad/rechtevorlagen/${result.id}`, { replace: true, state: { error: text } })
        else setError(text)
        return
      }
      navigate('/ad/rechtevorlagen')
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <BackLink />
        <h1 className="text-xl font-semibold">{isNew ? 'Neue Rechtevorlage' : data.template!.name}</h1>
        {!isNew && <p className="text-sm text-muted-foreground tabular-nums">{personCountLabel(data.personCount)}</p>}
      </div>

      <form className="flex flex-col gap-6" onSubmit={onSubmit} noValidate>
        <div className="flex max-w-md flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="template-name">Name</Label>
            <Input
              id="template-name"
              ref={nameRef}
              required
              value={name}
              onChange={(event) => setName(event.target.value)}
              aria-invalid={nameTaken || undefined}
              aria-describedby={nameTaken ? 'template-error' : undefined}
            />
            {nameTaken && <ErrorMessage text={error!} />}
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="template-description">
              Beschreibung <span className="font-normal text-muted-foreground">(optional)</span>
            </Label>
            <Input
              id="template-description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>
        </div>

        <fieldset className="flex flex-col gap-3">
          <legend className="mb-1 font-medium">Rechte je Modul</legend>
          <p className="mb-2 text-sm text-muted-foreground">
            Reichweite „Referat“ gibt es im Ehrenamtsmanagement, in der Anwesenheitserfassung, in der Planungshilfe und in
            Finanzen; die Referate legst du bei der Zuweisung fest. „Darf freigeben“: in Finanzen Abrechnungen als sachlich
            richtig bestätigen, in der Planungshilfe Planungen freigeben.
          </p>
          <RightsMatrix modules={data.modules} rights={rights} onChange={setLevel} onScopeChange={setScope} onApproveChange={setApprove} />
          <RightsList modules={data.modules} rights={rights} onChange={setLevel} onScopeChange={setScope} onApproveChange={setApprove} />
        </fieldset>

        {error && !nameTaken && <ErrorMessage text={error} />}

        <div className="flex flex-wrap gap-3">
          <Button type="submit" disabled={pending || !name.trim()}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
          <Button variant="outline" asChild>
            <Link to="/ad/rechtevorlagen">Abbrechen</Link>
          </Button>
        </div>
      </form>
    </section>
  )
}

function ErrorMessage({ text }: { text: string }) {
  return (
    <p id="template-error" role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}

type RightsProps = {
  modules: Module[]
  rights: Rights
  onChange: (code: string, level: Level) => void
  onScopeChange: (code: string, scope: Scope) => void
  onApproveChange: (code: string, approve: boolean) => void
}

const selectClassName =
  'h-8 rounded-lg border border-input bg-background px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-50'

// Reichweite nur dort wählbar, wo R30 sie erlaubt; sonst feste Anzeige „alle“
function ScopeSelect({ module, right, onScopeChange, id }: { module: Module; right: Right; onScopeChange: RightsProps['onScopeChange']; id: string }) {
  if (!allowsReferat(module.code)) {
    return <span className="text-sm text-muted-foreground">{SCOPE_LABELS.all}</span>
  }
  return (
    <select
      id={id}
      value={right.scope}
      onChange={(event) => onScopeChange(module.code, event.target.value as Scope)}
      aria-label={`${module.name}: Reichweite`}
      className={selectClassName}
    >
      {SCOPES.map((scope) => (
        <option key={scope} value={scope}>
          {SCOPE_LABELS[scope]}
        </option>
      ))}
    </select>
  )
}

// „Darf freigeben“ nur für Finanzen und Planungshilfe, nur mit einer Stufe (R50)
function ApproveCheckbox({ module, right, onApproveChange, id }: { module: Module; right: Right; onApproveChange: RightsProps['onApproveChange']; id: string }) {
  if (!allowsApprove(module.code)) return <span className="text-sm text-muted-foreground">–</span>
  return (
    <input
      id={id}
      type="checkbox"
      checked={right.approve}
      disabled={right.level === 'none'}
      onChange={(event) => onApproveChange(module.code, event.target.checked)}
      aria-label={`${module.name}: darf freigeben`}
      className="size-4 cursor-pointer accent-primary disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
    />
  )
}

// Ab 640 px: Matrix mit einer Optionsgruppe je Modul und den Spalten Reichweite und „darf freigeben“
function RightsMatrix({ modules, rights, onChange, onScopeChange, onApproveChange }: RightsProps) {
  return (
    <div className="hidden max-w-4xl overflow-hidden rounded-xl border sm:block">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b bg-muted">
            <th scope="col" className="h-10 px-4 text-left font-medium">
              Modul
            </th>
            {LEVELS.map((level) => (
              <th key={level} scope="col" className="h-10 px-2 text-center font-medium">
                {LEVEL_LABELS[level]}
              </th>
            ))}
            <th scope="col" className="h-10 px-4 text-left font-medium">
              Reichweite
            </th>
            <th scope="col" className="h-10 px-4 text-center font-medium">
              darf freigeben
            </th>
          </tr>
        </thead>
        <tbody>
          {modules.map((m) => (
            <tr key={m.code} className="border-b transition-colors last:border-0 hover:bg-accent/40">
              <th scope="row" className="px-4 py-1 text-left font-normal">
                {m.name}
              </th>
              {LEVELS.map((level) => (
                <td key={level} className="p-0 text-center">
                  <label className="flex h-10 cursor-pointer items-center justify-center">
                    <input
                      type="radio"
                      name={`level-${m.code}`}
                      value={level}
                      checked={(rights[m.code] ?? NONE).level === level}
                      onChange={() => onChange(m.code, level)}
                      aria-label={`${m.name}: ${LEVEL_LABELS[level]}`}
                      className="size-4 cursor-pointer accent-primary focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
                    />
                  </label>
                </td>
              ))}
              <td className="px-4 py-1">
                <ScopeSelect module={m} right={rights[m.code] ?? NONE} onScopeChange={onScopeChange} id={`scope-${m.code}`} />
              </td>
              <td className="px-4 py-1 text-center">
                <ApproveCheckbox module={m} right={rights[m.code] ?? NONE} onApproveChange={onApproveChange} id={`approve-${m.code}`} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// Unter 640 px: Liste mit je einem Auswahlfeld pro Modul, Reichweite und „darf freigeben“ darunter
function RightsList({ modules, rights, onChange, onScopeChange, onApproveChange }: RightsProps) {
  return (
    <ul className="flex flex-col divide-y rounded-xl border sm:hidden">
      {modules.map((m) => (
        <li key={m.code} className="flex flex-col gap-2 px-4 py-3">
          <label htmlFor={`level-select-${m.code}`} className="text-sm font-medium">
            {m.name}
          </label>
          <select
            id={`level-select-${m.code}`}
            value={(rights[m.code] ?? NONE).level}
            onChange={(event) => onChange(m.code, event.target.value as Level)}
            className="h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            {LEVELS.map((level) => (
              <option key={level} value={level}>
                {LEVEL_LABELS[level]}
              </option>
            ))}
          </select>
          {allowsReferat(m.code) && (
            <div className="flex items-center justify-between gap-3">
              <label htmlFor={`scope-select-${m.code}`} className="text-sm text-muted-foreground">
                Reichweite
              </label>
              <ScopeSelect module={m} right={rights[m.code] ?? NONE} onScopeChange={onScopeChange} id={`scope-select-${m.code}`} />
            </div>
          )}
          {allowsApprove(m.code) && (
            <div className="flex items-center justify-between gap-3">
              <label htmlFor={`approve-list-${m.code}`} className="text-sm text-muted-foreground">
                darf freigeben
              </label>
              <ApproveCheckbox module={m} right={rights[m.code] ?? NONE} onApproveChange={onApproveChange} id={`approve-list-${m.code}`} />
            </div>
          )}
        </li>
      ))}
    </ul>
  )
}
