import { useState } from 'react'
import { CheckIcon, CopyIcon, FileDownIcon } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { downloadPlanPdf } from '@/features/tk/ausgaben/pdf'
import { descText, summaryText, yolawoFields, type TextInput } from '@/features/tk/ausgaben/texts'
import { Section } from '@/features/tk/detail/fields'

async function copy(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch {
    return false
  }
}

function CopyButton({ text, label = 'Kopieren' }: { text: string; label?: string }) {
  const [done, setDone] = useState(false)
  return (
    <Button
      variant="outline"
      size="sm"
      onClick={async () => {
        if (await copy(text)) {
          setDone(true)
          window.setTimeout(() => setDone(false), 1500)
        } else toast.error('Kopieren nicht möglich. Bitte den Text markieren und kopieren.')
      }}
    >
      {done ? <CheckIcon data-icon="inline-start" aria-hidden="true" /> : <CopyIcon data-icon="inline-start" aria-hidden="true" />}
      {done ? 'Kopiert' : label}
    </Button>
  )
}

// T022, T023 (US-TK-15, -21): Reiter „Ausgaben“ – Yolawo-Eingabeblatt mit „Kopieren“ je Feld, Ausschreibungstext und
// Zusammenfassung mit „Alles kopieren“, PDF. Grundlage ist der aktuelle Stand im Formular (Live-Kalkulation).
export function AusgabenTab({ input, missingLabels }: { input: TextInput; missingLabels: string[] }) {
  const [pending, setPending] = useState(false)
  const fields = yolawoFields(input)
  const desc = descText(input)
  const summary = summaryText(input, missingLabels)

  async function pdf() {
    setPending(true)
    const error = await downloadPlanPdf(input, missingLabels)
    setPending(false)
    if (error) toast.error(error)
  }

  return (
    <div className="flex flex-col gap-10">
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl bg-muted p-4 text-sm">
        <span>{missingLabels.length ? `Noch unvollständig. Es fehlen: ${missingLabels.join(', ')}` : 'Vollständig ausgefüllt.'}</span>
        <Button onClick={pdf} disabled={pending}>
          <FileDownIcon data-icon="inline-start" aria-hidden="true" />
          {pending ? 'PDF wird erstellt …' : 'PDF herunterladen'}
        </Button>
      </div>

      <Section title="Yolawo-Eingabeblatt" description="Feld für Feld in die Yolawo-Verwaltung übertragen.">
        <dl className="flex flex-col divide-y rounded-xl border">
          {fields.map((f) => (
            <div key={`${f.group}-${f.field}`} className="grid gap-2 p-3 sm:grid-cols-[12rem_1fr_auto] sm:items-start">
              <dt className="text-sm">
                <span className="block text-xs text-muted-foreground">{f.group}</span>
                {f.field}
              </dt>
              <dd className={f.value === null ? 'text-sm text-destructive' : 'text-sm whitespace-pre-line'}>{f.value ?? 'fehlt'}</dd>
              {f.value !== null && f.field !== 'Beschreibung' && <CopyButton text={f.value} />}
            </div>
          ))}
        </dl>
      </Section>

      <Section title="Ausschreibungstext" description="Für die Beschreibung in Yolawo; Abschnittsüberschriften dort fett setzen.">
        <div>
          <CopyButton text={desc} label="Alles kopieren" />
        </div>
        <pre className="rounded-xl border bg-background p-4 font-sans text-sm whitespace-pre-wrap">{desc}</pre>
      </Section>

      <Section title="Zusammenfassung" description="Alle Angaben als Text, z. B. für eine E-Mail an das Referat.">
        <div>
          <CopyButton text={summary} label="Alles kopieren" />
        </div>
        <pre className="max-h-[32rem] overflow-y-auto rounded-xl border bg-background p-4 font-sans text-sm whitespace-pre-wrap">{summary}</pre>
      </Section>
    </div>
  )
}
