import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { FormError } from '@/features/gr/shared/ui'
import { PLAN_TYPE_HINTS, PLAN_TYPE_LABELS } from '@/features/tk/labels'
import { tkRpc } from '@/features/tk/rpc'
import type { PlanType } from '@/features/tk/types'
import { cn } from '@/lib/utils'

const TYPES: PlanType[] = ['guided_tour', 'course', 'community_tour']

// T018 (US-TK-02): Tourtyp (drei Karten wie Prototyp Schritt 1) und Titel → Entwurf anlegen und öffnen.
// Das Referat folgt aus dem Tourtyp (R12); ohne Recht im Ziel-Referat meldet die Datenbank TK_FORBIDDEN_REFERAT.
export function PlanungNeuPage() {
  const navigate = useNavigate()
  const [type, setType] = useState<PlanType | null>(null)
  const [title, setTitle] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)
  const [requestId] = useState(() => crypto.randomUUID())

  async function submit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    if (!type) return setError('Bitte einen Tourtyp wählen.')
    if (!title.trim()) return setError('Bitte einen Titel eingeben.')
    setPending(true)
    const res = await tkRpc<{ id: string }>('tk_save_plan', {
      p_plan: { plan_type: type, title: title.trim(), client_request_id: requestId },
      p_leaders: null,
      p_contacts: null,
      p_legs: null,
      p_costs: null,
    })
    setPending(false)
    if (res.error) return setError(res.error.text)
    navigate(`/tk/${res.data.id}`)
  }

  return (
    <form onSubmit={submit} noValidate className="flex max-w-3xl flex-col gap-6">
      <h1 className="text-2xl font-semibold tracking-tight">Neue Planung</h1>
      <fieldset className="flex flex-col gap-3">
        <legend className="mb-3 text-sm font-medium">Tourtyp</legend>
        <div className="grid gap-3 sm:grid-cols-3">
          {TYPES.map((t) => (
            <label
              key={t}
              className={cn(
                'flex cursor-pointer flex-col gap-1 rounded-xl border p-4 transition-colors has-focus-visible:ring-3 has-focus-visible:ring-ring/50',
                type === t ? 'border-primary bg-primary/5' : 'hover:bg-muted',
              )}
            >
              <input type="radio" name="tk-type" value={t} checked={type === t} onChange={() => setType(t)} className="sr-only" />
              <span className="font-medium">{PLAN_TYPE_LABELS[t]}</span>
              <span className="text-sm text-muted-foreground">{PLAN_TYPE_HINTS[t]}</span>
            </label>
          ))}
        </div>
      </fieldset>
      <div className="flex flex-col gap-2">
        <Label htmlFor="tk-new-title">Titel</Label>
        <Input id="tk-new-title" value={title} maxLength={90} onChange={(e) => setTitle(e.target.value)} autoComplete="off" />
        <p className="text-xs text-muted-foreground">Höchstens 90 Zeichen.</p>
      </div>
      <FormError text={error} />
      <div>
        <Button type="submit" disabled={pending}>
          {pending ? 'Wird angelegt …' : 'Planung anlegen'}
        </Button>
      </div>
    </form>
  )
}
