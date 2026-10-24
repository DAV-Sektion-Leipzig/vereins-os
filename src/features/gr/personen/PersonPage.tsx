import { useState, type ReactNode } from 'react'
import { ChevronLeftIcon, PencilIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Section } from '@/features/ad/personen/Section'
import { useGrAccess } from '@/features/gr/access'
import { continueHref } from '@/features/gr/aufnahme/data'
import { CONTRACT_STATUS_LABELS, isRunning, type ContractStatus } from '@/features/gr/gruppen/detail'
import { MemberHints } from '@/features/gr/gruppen/GruppeDetailPage'
import { ErziehungsberechtigteAbschnitt, NotfallkontakteAbschnitt } from '@/features/gr/personen/Beziehungen'
import { type ContractRow, type GrPerson, type GrPersonResult } from '@/features/gr/personen/data'
import { FotoerlaubnisAbschnitt, GesundheitAbschnitt } from '@/features/gr/personen/Einwilligungen'
import { ContactLinks } from '@/features/gr/personen/PersonFelder'
import { StammdatenDialog } from '@/features/gr/personen/StammdatenDialog'
import { VertragDialog, type ContractAction } from '@/features/gr/personen/VertragDialog'
import { HintBadge, LoadFailed } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { ageOn, formatDate, personName, todayIso } from '@/lib/format'

const NOT_FOUND = 'Diese Person wurde nicht gefunden oder du hast keine Rechte.'

// T038 (US-GR-14): Teilnehmer:in mit Notfallkontakten oben (mobil: Gruppe → Kind → Notfallkontakte), Stammdaten,
// Erziehungsberechtigte, Teilnahmen mit Verträgen, Fotoerlaubnis, Gesundheit (nur bearbeiten). Für
// Erziehungsberechtigte, Notfallkontakte und Betreuer:innen: Stammdaten und Bezüge.
export function PersonPage() {
  const result = useLoaderData() as GrPersonResult
  const navigate = useNavigate()
  const revalidator = useRevalidator()
  const { canEdit, canManage } = useGrAccess()
  const [editing, setEditing] = useState(false)
  const [contractAction, setContractAction] = useState<ContractAction | null>(null)

  if (result.state !== 'ok') {
    return (
      <section className="flex flex-col gap-4">
        <BackLink onClick={() => navigate(-1)} />
        <LoadFailed text={result.state === 'not_found' ? NOT_FOUND : MESSAGES.unexpected} />
      </section>
    )
  }

  const d = result.data
  const reload = () => revalidator.revalidate()
  const isParticipant = d.memberships.length > 0 || d.pending !== null
  const runningMember = d.memberships.some((m) => isRunning(m.left_on))
  const holders = [...d.guardians.map((g) => g.person), d.person]

  return (
    <section className="flex flex-col gap-8">
      <div className="flex flex-col gap-3">
        <BackLink onClick={() => navigate(-1)} />
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="flex flex-col gap-1">
            <h1 className="text-xl font-semibold">{personName(d.person)}</h1>
            <p className="text-sm text-muted-foreground">{roleLine(d)}</p>
          </div>
          {canEdit && (
            <Button variant="outline" onClick={() => setEditing(true)} className="h-11 sm:h-8">
              <PencilIcon data-icon="inline-start" aria-hidden="true" />
              Stammdaten ändern
            </Button>
          )}
        </div>
        {d.pending && (
          <p className="flex flex-wrap items-center gap-2 text-sm">
            <HintBadge>Aufnahme offen in {d.pending.group_name}</HintBadge>
            {canEdit && (
              <Link to={continueHref({ group_id: d.pending.group_id, person_id: d.person.id })} className="underline-offset-4 hover:underline">
                Aufnahme fortsetzen
              </Link>
            )}
          </p>
        )}
        {d.needsGuardian && (
          <span>
            <HintBadge>Bitte mindestens eine erziehungsberechtigte Person angeben.</HintBadge>
          </span>
        )}
      </div>

      {isParticipant && (
        <Section id="gr-notfall" title="Notfallkontakte">
          {d.emergencyContacts.length === 0 && (
            <div className="flex flex-col gap-2">
              {runningMember && (
                <span>
                  <HintBadge>Kein Notfallkontakt hinterlegt.</HintBadge>
                </span>
              )}
              {d.guardians.length > 0 && (
                <ul className="flex flex-col gap-2">
                  {d.guardians.map((g) => (
                    <li key={g.id} className="flex flex-col gap-1">
                      <span className="font-medium">{personName(g.person)} (erziehungsberechtigt)</span>
                      <ContactLinks contact={g.person.contact} />
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
          <NotfallkontakteAbschnitt
            childId={d.person.id}
            contacts={d.emergencyContacts}
            guardians={d.guardians}
            editable={canEdit}
            onChanged={reload}
          />
        </Section>
      )}

      <Section id="gr-stammdaten" title="Stammdaten">
        <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[auto_1fr]">
          <Row label="Name">{`${d.person.first_name} ${d.person.last_name}`}</Row>
          {d.person.preferred_name && <Row label="Rufname">{d.person.preferred_name}</Row>}
          {d.person.birth_date && (
            <Row label="Geburtsdatum">
              {formatDate(d.person.birth_date)} ({ageOn(d.person.birth_date, todayIso())} Jahre)
            </Row>
          )}
          <Row label="Adresse">
            {[d.person.contact.street, [d.person.contact.postal_code, d.person.contact.city].filter(Boolean).join(' ')].filter(Boolean).join(', ') ||
              '–'}
          </Row>
          <Row label="Kontakt">
            <ContactLinks contact={d.person.contact} />
          </Row>
          {d.person.member_number && <Row label="Mitgliedsnummer">{d.person.member_number}</Row>}
        </dl>
      </Section>

      {isParticipant && (
        <Section id="gr-erziehungsberechtigte" title="Erziehungsberechtigte">
          <ErziehungsberechtigteAbschnitt childId={d.person.id} guardians={d.guardians} editable={canEdit} onChanged={reload} />
        </Section>
      )}

      {d.memberships.length > 0 && (
        <Section id="gr-teilnahmen" title="Teilnahmen und Verträge">
          <ul className="flex flex-col gap-4">
            {d.memberships.map((m) => {
              const contracts = d.contracts.filter((c) => c.membership_id === m.membership_id)
              const open = contracts.find((c) => !c.ends_on)
              const running = isRunning(m.left_on)
              return (
                <li key={m.membership_id} className="flex flex-col gap-3 rounded-xl border p-4">
                  <div className="flex flex-wrap items-start justify-between gap-2">
                    <span className="flex flex-col gap-0.5">
                      <Link to={`/gr/gruppen/${m.group_id}`} className="font-medium underline-offset-4 hover:underline">
                        {m.group_name}
                      </Link>
                      <span className="text-sm text-muted-foreground">
                        seit {formatDate(m.joined_on)}
                        {m.left_on && ` · Teilnahme bis ${formatDate(m.left_on)}`}
                      </span>
                    </span>
                    {canEdit && (
                      <span className="flex flex-wrap gap-2">
                        {open && (
                          <Button variant="outline" className="h-11 sm:h-8" onClick={() => setContractAction({ kind: 'cancel', contract: open, membership: m })}>
                            Vertrag kündigen
                          </Button>
                        )}
                        {!open && running && (
                          <Button variant="outline" className="h-11 sm:h-8" onClick={() => setContractAction({ kind: 'follow', membership: m })}>
                            Folgevertrag
                          </Button>
                        )}
                        <Button variant="ghost" className="h-11 sm:h-8" onClick={() => setContractAction({ kind: 'end', membership: m })}>
                          {m.left_on ? '„Teilnahme bis“ ändern' : 'Teilnahme beenden'}
                        </Button>
                      </span>
                    )}
                  </div>
                  <MemberHints m={m} />
                  <ul className="flex flex-col divide-y rounded-lg border">
                    {contracts.map((c) => (
                      <ContractItem
                        key={c.id}
                        contract={c}
                        holderName={holderName(d, c)}
                        onEdit={canEdit ? () => setContractAction({ kind: 'edit', contract: c }) : undefined}
                        onCancel={canEdit && c.ends_on ? () => setContractAction({ kind: 'cancel', contract: c, membership: m }) : undefined}
                      />
                    ))}
                  </ul>
                </li>
              )
            })}
          </ul>
        </Section>
      )}

      {(d.guardianOf.length > 0 || d.emergencyContactOf.length > 0 || d.functions.length > 0) && (
        <Section id="gr-bezuege" title="Bezüge in Gruppen">
          <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[auto_1fr]">
            {d.guardianOf.length > 0 && <Row label="erziehungsberechtigt für">{personLinks(d.guardianOf)}</Row>}
            {d.emergencyContactOf.length > 0 && <Row label="Notfallkontakt für">{personLinks(d.emergencyContactOf)}</Row>}
            {d.functions.length > 0 && (
              <Row label="Funktionen">
                <ul className="flex flex-col gap-1">
                  {d.functions.map((f) => (
                    <li key={f.id}>
                      {f.function} – <Link to={`/gr/gruppen/${f.group_id}`} className="underline-offset-4 hover:underline">{f.group_name}</Link>
                      <span className="text-muted-foreground">
                        {' '}
                        · seit {formatDate(f.valid_from)}
                        {f.valid_to && ` bis ${formatDate(f.valid_to)}`}
                      </span>
                    </li>
                  ))}
                </ul>
              </Row>
            )}
          </dl>
        </Section>
      )}

      {isParticipant && (
        <Section id="gr-foto" title="Fotoerlaubnis">
          <FotoerlaubnisAbschnitt personId={d.person.id} rows={d.photoConsents} editable={canEdit} onChanged={reload} />
        </Section>
      )}

      {isParticipant && canEdit && (
        <Section id="gr-gesundheit" title="Gesundheit">
          <GesundheitAbschnitt personId={d.person.id} consents={d.healthConsents} note={d.healthNote} history={d.healthHistory} onChanged={reload} />
        </Section>
      )}

      {editing && <StammdatenDialog person={d.person} canManage={canManage} onClose={() => setEditing(false)} onDone={() => (setEditing(false), reload())} />}
      {contractAction && (
        <VertragDialog action={contractAction} holders={holders} onClose={() => setContractAction(null)} onDone={() => (setContractAction(null), reload())} />
      )}
    </section>
  )
}

function BackLink({ onClick }: { onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} className="inline-flex min-h-11 items-center gap-1 self-start text-sm text-muted-foreground hover:text-foreground sm:min-h-0">
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Zurück
    </button>
  )
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <>
      <dt className="text-muted-foreground">{label}</dt>
      <dd>{children}</dd>
    </>
  )
}

function roleLine(d: GrPerson): string {
  const parts = [
    d.memberships.some((m) => isRunning(m.left_on)) && `Teilnehmer:in (${d.memberships.filter((m) => isRunning(m.left_on)).map((m) => m.group_name).join(', ')})`,
    d.guardianOf.length > 0 && 'erziehungsberechtigt',
    d.emergencyContactOf.length > 0 && 'Notfallkontakt',
    d.functions.some((f) => isRunning(f.valid_to)) && 'Betreuung',
  ].filter(Boolean)
  return parts.join(' · ')
}

function personLinks(persons: GrPerson['guardianOf']) {
  return persons.map((p, i) => (
    <span key={p.id}>
      {i > 0 && ', '}
      <Link to={`/gr/personen/${p.id}`} className="underline-offset-4 hover:underline">
        {personName(p)}
      </Link>
    </span>
  ))
}

function holderName(d: GrPerson, c: ContractRow): string {
  if (c.holder_person_id === d.person.id) return personName(d.person)
  const g = d.guardians.find((x) => x.person.id === c.holder_person_id)
  return g ? personName(g.person) : c.account_holder
}

function contractStatus(c: ContractRow): ContractStatus {
  return !c.ends_on ? 'active' : c.ends_on >= todayIso() ? 'cancelled' : 'ended'
}

function ContractItem({
  contract: c,
  holderName,
  onEdit,
  onCancel,
}: {
  contract: ContractRow
  holderName: string
  onEdit?: () => void
  onCancel?: () => void
}) {
  const status = contractStatus(c)
  return (
    <li className="flex flex-col gap-2 px-3 py-2.5 text-sm sm:flex-row sm:items-start sm:justify-between">
      <span className="flex flex-col gap-0.5">
        <span className="font-medium">
          {status === 'cancelled' && c.ends_on ? `gekündigt zum ${formatDate(c.ends_on)}` : CONTRACT_STATUS_LABELS[status]}
          {status === 'ended' && c.ends_on && ` am ${formatDate(c.ends_on)}`}
        </span>
        <span className="text-muted-foreground">
          ab {formatDate(c.starts_on)} · {Number(c.monthly_amount).toLocaleString('de-DE', { style: 'currency', currency: 'EUR' })} je Monat ·
          Vertragsinhaber:in {holderName}
        </span>
        <span className="text-muted-foreground">
          {c.account_holder} · {c.iban} · Mandat {c.mandate_reference} vom {formatDate(c.mandate_signed_on)}
        </span>
        <span className="text-muted-foreground">{c.purpose}</span>
        {c.cancelled_on && <span className="text-muted-foreground">Kündigung eingegangen am {formatDate(c.cancelled_on)}</span>}
      </span>
      <span className="flex flex-wrap gap-2">
        {onEdit && (
          <Button variant="ghost" className="h-11 sm:h-8" onClick={onEdit}>
            Ändern
          </Button>
        )}
        {onCancel && (
          <Button variant="ghost" className="h-11 sm:h-8" onClick={onCancel}>
            Vertragsende ändern
          </Button>
        )}
      </span>
    </li>
  )
}
