import { ArrowDownIcon, ArrowUpIcon, PlusIcon, Trash2Icon, UserPlusIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { AktivenSuche } from '@/features/ez/shared/AktivenSuche'
import type { CalcResult } from '@/features/tk/calc'
import type { Draft, DraftLeader } from '@/features/tk/detail/data'
import { AreaField, CheckField, NumberField, RadioField, Section, SelectField, SuggestedNumber, TextField } from '@/features/tk/detail/fields'
import {
  ACCOMMODATION_LABELS, COST_GROUP_LABELS, FITNESS_LABELS, formatKg, formatMoney, IMAGE_LABELS, PAYMENT_LABELS,
  PREBRIEFING_LABELS, PUBLIC_TRANSPORT_LABELS, REGISTRATION_QUESTIONS, ROLE_LABELS, SPORTS, TARGET_GROUPS,
  TECHNIQUE_HINTS, TECHNIQUE_LABELS, TRANSPORT_LABELS, VEHICLE_MODES, YOLAWO_LABELS,
} from '@/features/tk/labels'
import type { Accommodation, Cost, CostGroup, Fitness, LeaderRole, Leg, PlanDetail, PlanFields, Rates, Technique, Transport } from '@/features/tk/types'
import { formatDate } from '@/lib/format'

export type StepProps = {
  draft: Draft
  detail: PlanDetail
  calc: CalcResult
  rates: Rates
  disabled: boolean
  missing: Set<string>
  setFields: (patch: Partial<PlanFields>) => void
  setDraft: (fn: (d: Draft) => Draft) => void
}

function opts<T extends string>(labels: Record<T, string>): { value: T; label: string }[] {
  return (Object.keys(labels) as T[]).map((value) => ({ value, label: labels[value] }))
}

function rateValue(rates: Rates, key: string): number | null {
  const v = rates[key]?.value
  return v === null || v === undefined ? null : Number(v)
}

/** Feld mit Vorschlag ändern: Wert setzen und als „geändert“ merken (Prototyp 4.2). */
function touch(p: StepProps, key: keyof PlanFields, value: number | null) {
  const touched = new Set(p.draft.fields.touched)
  touched.add(key)
  p.setFields({ [key]: value, touched: [...touched] } as Partial<PlanFields>)
}
function untouch(p: StepProps, key: keyof PlanFields) {
  p.setFields({ touched: p.draft.fields.touched.filter((k) => k !== key) })
}

// Schritt 1 „Leitung“ (US-TK-03, -04; R2, R13, R17, R23)
export function Step1(p: StepProps & { onNewPerson: () => void }) {
  const { draft, disabled, detail } = p
  const isCommunity = draft.fields.plan_type === 'community_tour'
  const leaders = draft.leaders

  function update(fn: (l: DraftLeader[]) => DraftLeader[]) {
    p.setDraft((d) => ({ ...d, leaders: fn(d.leaders) }))
  }
  function move(i: number, dir: -1 | 1) {
    update((l) => {
      const next = [...l]
      const [x] = next.splice(i, 1)
      next.splice(i + dir, 0, x)
      return next
    })
  }
  function setContact(personId: string, key: 'email' | 'mobile' | 'emergency_name' | 'emergency_phone', value: string | null) {
    p.setDraft((d) => ({
      ...d,
      contacts: { ...d.contacts, [personId]: { ...(d.contacts[personId] ?? { person_id: personId, email: null, mobile: null, emergency_name: null, emergency_phone: null }), [key]: value } },
    }))
  }

  return (
    <div className="flex flex-col gap-8">
      {isCommunity && (
        <AreaField
          label="Begründung für die Gemeinschaftstour"
          value={draft.fields.community_reason}
          onChange={(v) => p.setFields({ community_reason: v })}
          disabled={disabled}
          missing={p.missing.has('community_reason')}
        />
      )}
      <Section title="Leitung und Helfende" description="Personen aus den Aktiven; die Satzart ergibt sich aus den Lizenzen im Ehrenamtsmanagement.">
        {leaders.length === 0 && <p className={p.missing.has('leader') ? 'text-sm text-destructive' : 'text-sm text-muted-foreground'}>Noch keine Person eingetragen.</p>}
        <ul className="flex flex-col gap-3">
          {leaders.map((l, i) => (
            <li key={l.person_id} className="flex flex-col gap-3 rounded-xl border p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex flex-col gap-1">
                  <span className="font-medium">{l.name}</span>
                  <span className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                    {l.rate_kind ? (
                      <Badge variant="outline">{l.rate_kind === 'trainer' ? 'Trainersatz' : 'Helfersatz'}</Badge>
                    ) : (
                      <Badge variant="outline">Satzart nach dem Speichern</Badge>
                    )}
                    {l.license_name && (
                      <span>
                        {l.license_name}
                        {l.license_valid_until ? `, gültig bis ${formatDate(l.license_valid_until)}` : ''}
                        {l.license_valid_from && draft.fields.start_date && l.license_valid_from > draft.fields.start_date
                          ? `, erworben am ${formatDate(l.license_valid_from)}`
                          : ''}
                      </span>
                    )}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <select
                    aria-label={`Rolle von ${l.name}`}
                    className="h-8 rounded-lg border border-input bg-background px-2.5 text-sm"
                    value={l.role}
                    disabled={disabled}
                    onChange={(e) => update((all) => all.map((x) => (x.person_id === l.person_id ? { ...x, role: e.target.value as LeaderRole } : x)))}
                  >
                    {opts(ROLE_LABELS).map((o) => (
                      <option key={o.value} value={o.value}>
                        {o.label}
                      </option>
                    ))}
                  </select>
                  {!disabled && (
                    <>
                      <Button variant="ghost" size="icon" aria-label="nach oben" disabled={i === 0} onClick={() => move(i, -1)}>
                        <ArrowUpIcon aria-hidden="true" />
                      </Button>
                      <Button variant="ghost" size="icon" aria-label="nach unten" disabled={i === leaders.length - 1} onClick={() => move(i, 1)}>
                        <ArrowDownIcon aria-hidden="true" />
                      </Button>
                      <Button variant="ghost" size="icon" aria-label={`${l.name} entfernen`} onClick={() => update((all) => all.filter((x) => x.person_id !== l.person_id))}>
                        <Trash2Icon aria-hidden="true" />
                      </Button>
                    </>
                  )}
                </div>
              </div>
              {detail.can_read_contacts && l.role !== 'helper' && !detail.plan.contacts_purged_at && (
                <div className="grid gap-3 sm:grid-cols-2">
                  <TextField label="E-Mail" type="email" value={draft.contacts[l.person_id]?.email ?? null} disabled={disabled}
                    missing={i === leaders.findIndex((x) => x.role === 'lead') && p.missing.has('contact_email')}
                    onChange={(v) => setContact(l.person_id, 'email', v)} />
                  <TextField label="Mobilnummer für die Tour" type="tel" value={draft.contacts[l.person_id]?.mobile ?? null} disabled={disabled}
                    onChange={(v) => setContact(l.person_id, 'mobile', v)} />
                  <TextField label="Notfallkontakt (Name)" value={draft.contacts[l.person_id]?.emergency_name ?? null} disabled={disabled}
                    missing={i === leaders.findIndex((x) => x.role === 'lead') && p.missing.has('emergency_name')}
                    onChange={(v) => setContact(l.person_id, 'emergency_name', v)} />
                  <TextField label="Telefon Notfallkontakt" type="tel" value={draft.contacts[l.person_id]?.emergency_phone ?? null} disabled={disabled}
                    missing={i === leaders.findIndex((x) => x.role === 'lead') && p.missing.has('emergency_phone')}
                    onChange={(v) => setContact(l.person_id, 'emergency_phone', v)} />
                </div>
              )}
            </li>
          ))}
        </ul>
        {detail.plan.contacts_purged_at && (
          <p className="text-sm text-muted-foreground">Kontakt- und Notfalldaten gelöscht am {formatDate(detail.plan.contacts_purged_at)}.</p>
        )}
        {detail.can_read_contacts && !detail.plan.contacts_purged_at && (
          <p className="text-xs text-muted-foreground">
            Kontakt- und Notfalldaten sehen nur Personen, die die Planung bearbeiten dürfen. Sie werden 30 Tage nach Tourende
            bzw. Absage automatisch gelöscht.
          </p>
        )}
        {!disabled && (
          <div className="flex flex-col gap-3 rounded-xl border border-dashed p-4">
            <AktivenSuche
              label="Person hinzufügen"
              excludeIds={leaders.map((l) => l.person_id)}
              onSelect={(person) =>
                update((all) => [
                  ...all,
                  {
                    person_id: person.id,
                    name: `${person.preferred_name?.trim() || person.first_name} ${person.last_name}`,
                    role: all.some((x) => x.role === 'lead') ? 'co_lead' : 'lead',
                    rate_kind: null,
                    license_name: null,
                    license_valid_from: null,
                    license_valid_until: null,
                  },
                ])
              }
            />
            <div>
              <Button variant="outline" onClick={p.onNewPerson}>
                <UserPlusIcon data-icon="inline-start" aria-hidden="true" />
                Neue Person anlegen
              </Button>
            </div>
          </div>
        )}
      </Section>
    </div>
  )
}

// Schritt 2 „Ausschreibung“
export function Step2(p: StepProps) {
  const f = p.draft.fields
  const d = p.disabled
  return (
    <div className="grid gap-6 sm:grid-cols-2">
      <TextField className="sm:col-span-2" label="Titel" value={f.title} maxLength={90} disabled={d} hint="Höchstens 90 Zeichen."
        onChange={(v) => p.setFields({ title: v ?? '' })} />
      <SelectField label="Sportart" value={f.sport} empty="Bitte wählen" options={SPORTS.map((s) => ({ value: s, label: s }))}
        disabled={d} missing={p.missing.has('sport')} onChange={(v) => p.setFields({ sport: v })} />
      <fieldset className="flex flex-col gap-2" disabled={d}>
        <legend className="mb-2 text-sm font-medium">Zielgruppe / Reihe</legend>
        {TARGET_GROUPS.map((g) => (
          <CheckField key={g.value} label={g.label} checked={f.target_groups.includes(g.value)}
            onChange={(on) => p.setFields({ target_groups: on ? [...f.target_groups, g.value] : f.target_groups.filter((x) => x !== g.value) })} />
        ))}
      </fieldset>
      <TextField label="Gebiet / Region" value={f.region} disabled={d} missing={p.missing.has('region')} onChange={(v) => p.setFields({ region: v })} />
      <TextField label="Stützpunkt / Unterkunft" value={f.base} disabled={d} onChange={(v) => p.setFields({ base: v })} />
      <AreaField className="sm:col-span-2" label="Kurzbeschreibung" hint="2–4 Sätze; erster Absatz der Ausschreibung." value={f.teaser}
        disabled={d} missing={p.missing.has('teaser')} onChange={(v) => p.setFields({ teaser: v })} />
      <AreaField className="sm:col-span-2" label="Ablauf / Programm" value={f.programme} disabled={d} onChange={(v) => p.setFields({ programme: v })} />
      <RadioField label="Titelbild" value={f.image_source} options={opts(IMAGE_LABELS)} disabled={d} missing={p.missing.has('image_source')}
        onChange={(v) => p.setFields({ image_source: v })} />
      {f.image_source === 'own' && (
        <TextField label="Bildrechte" hint="z. B. „Foto: Vorname Nachname“" value={f.image_credit} disabled={d}
          missing={p.missing.has('image_credit')} onChange={(v) => p.setFields({ image_credit: v })} />
      )}
    </div>
  )
}

// Schritt 3 „Termin & Anreise“ (Teilstrecken, Unterkunft, CO2)
export function Step3(p: StepProps) {
  const f = p.draft.fields
  const d = p.disabled
  const legs = p.draft.legs
  function setLegs(fn: (l: Leg[]) => Leg[]) {
    p.setDraft((x) => ({ ...x, legs: fn(x.legs) }))
  }
  function setLeg(i: number, patch: Partial<Leg>) {
    setLegs((l) => l.map((x, j) => (j === i ? { ...x, ...patch, vehicles: VEHICLE_MODES.includes((patch.mode ?? x.mode) as Transport) ? (patch.vehicles ?? x.vehicles) : 0 } : x)))
  }
  const kg = (l: Leg) => {
    const ef = rateValue(p.rates, `ef_${l.mode}`) ?? 0
    const count = VEHICLE_MODES.includes(l.mode) ? l.vehicles : l.persons
    return (l.km_one_way * (l.round_trip ? 2 : 1) * count * ef) / 1000
  }
  const days = p.calc.days
  return (
    <div className="flex flex-col gap-8">
      <div className="grid gap-6 sm:grid-cols-2">
        <TextField label="Beginn" type="date" value={f.start_date} disabled={d} missing={p.missing.has('start_date')} onChange={(v) => p.setFields({ start_date: v })} />
        <TextField label="Treffzeit" type="time" value={f.meet_time} disabled={d} missing={p.missing.has('meet_time')} onChange={(v) => p.setFields({ meet_time: v })} />
        <TextField label="Ende" type="date" value={f.end_date} disabled={d} missing={p.missing.has('end_date')} onChange={(v) => p.setFields({ end_date: v })} />
        <TextField label="Voraussichtliches Ende" type="time" value={f.end_time} disabled={d} onChange={(v) => p.setFields({ end_time: v })} />
        {days > 0 && (
          <p className="text-sm text-muted-foreground sm:col-span-2">
            {days === 1 ? 'Tagestour' : days <= 3 ? 'Wochenendtour' : 'Mehrtagestour'}, {days} Tag(e)
            {p.calc.hours_day1 !== null ? `, ca. ${p.calc.hours_day1} h am ersten Tag` : ''}
          </p>
        )}
        <TextField label="Treffpunkt" value={f.meeting_point} disabled={d} missing={p.missing.has('meeting_point')} onChange={(v) => p.setFields({ meeting_point: v })} />
        <TextField label="Adresse oder Koordinaten" value={f.meeting_coords} disabled={d} onChange={(v) => p.setFields({ meeting_coords: v })} />
        <SelectField label="Vorbesprechung" value={f.prebriefing} options={opts(PREBRIEFING_LABELS)} disabled={d}
          onChange={(v) => p.setFields({ prebriefing: v ?? 'none', prebriefing_at: v === 'none' ? null : f.prebriefing_at })} />
        {f.prebriefing !== 'none' && (
          <TextField label="Datum der Vorbesprechung" type="datetime-local" value={f.prebriefing_at} disabled={d} onChange={(v) => p.setFields({ prebriefing_at: v })} />
        )}
        <RadioField className="sm:col-span-2" label="Anreise mit öffentlichen Verkehrsmitteln" value={f.public_transport} options={opts(PUBLIC_TRANSPORT_LABELS)}
          disabled={d} missing={p.missing.has('public_transport')} onChange={(v) => p.setFields({ public_transport: v })} />
        <AreaField className="sm:col-span-2" label="Anreisehinweise" value={f.travel_notes} disabled={d} onChange={(v) => p.setFields({ travel_notes: v })} />
        <CheckField label="Treffpunkt höchstens 1,5 km von einer ÖPV-Haltestelle" checked={f.meeting_near_pt} disabled={d}
          onChange={(v) => p.setFields({ meeting_near_pt: v })} />
      </div>

      <Section title="Geplante An- und Abreise" description="Für die CO2-Bilanz; PKW, E-PKW und Kleinbus nach Fahrzeugen, sonst nach Personen.">
        {p.missing.has('travel_legs') && <p className="text-sm text-destructive">Bitte mindestens eine Teilstrecke mit km und Personen bzw. Fahrzeugen angeben.</p>}
        <div className="flex flex-col gap-3">
          {legs.map((l, i) => (
            <div key={i} className="grid items-end gap-3 rounded-xl border p-3 sm:grid-cols-[1.4fr_1.4fr_0.7fr_0.7fr_0.7fr_auto_auto]">
              <SelectField label="Verkehrsmittel" value={l.mode} options={opts(TRANSPORT_LABELS)} disabled={d} onChange={(v) => v && setLeg(i, { mode: v })} />
              <TextField label="Strecke" value={l.label} disabled={d} onChange={(v) => setLeg(i, { label: v })} />
              <NumberField label="km einfach" value={l.km_one_way} disabled={d} onChange={(v) => setLeg(i, { km_one_way: v ?? 0 })} />
              <NumberField label="Personen" value={l.persons} disabled={d} onChange={(v) => setLeg(i, { persons: v ?? 0 })} />
              <NumberField label="Fahrzeuge" value={l.vehicles} disabled={d || !VEHICLE_MODES.includes(l.mode)} onChange={(v) => setLeg(i, { vehicles: v ?? 0 })} />
              <CheckField label="hin und zurück" checked={l.round_trip} disabled={d} onChange={(v) => setLeg(i, { round_trip: v })} />
              <div className="flex items-center justify-between gap-2 sm:justify-end">
                <span className="text-sm tabular-nums">{formatKg(kg(l))}</span>
                {!d && (
                  <Button variant="ghost" size="icon" aria-label="Teilstrecke entfernen" onClick={() => setLegs((x) => x.filter((_, j) => j !== i))}>
                    <Trash2Icon aria-hidden="true" />
                  </Button>
                )}
              </div>
            </div>
          ))}
        </div>
        {!d && (
          <div>
            <Button variant="outline" onClick={() => setLegs((x) => [...x, { mode: 'rail_long', label: null, km_one_way: 0, persons: f.co2_persons ?? p.calc.suggestions.co2_persons ?? 0, vehicles: 0, round_trip: true }])}>
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Teilstrecke
            </Button>
          </div>
        )}
      </Section>

      <div className="grid gap-6 sm:grid-cols-3">
        <SelectField<Accommodation> label="Unterkunft" value={f.accommodation} options={opts(ACCOMMODATION_LABELS)} disabled={d}
          onChange={(v) => p.setFields({ accommodation: v ?? 'none' })} />
        <SuggestedNumber label="Nächte" value={f.nights} suggestion={p.calc.suggestions.nights} touched={f.touched.includes('nights')}
          disabled={d} onChange={(v) => touch(p, 'nights', v)} onReset={() => untouch(p, 'nights')} />
        <SuggestedNumber label="Personen gesamt (Planung)" value={f.co2_persons} suggestion={p.calc.suggestions.co2_persons}
          touched={f.touched.includes('co2_persons')} disabled={d} onChange={(v) => touch(p, 'co2_persons', v)} onReset={() => untouch(p, 'co2_persons')}
          hint="Höchstanzahl Teilnehmende plus Leitung." />
      </div>
    </div>
  )
}

// Schritt 4 „Anforderungen“ (Kondition, Technik, Mitgliedschaft R5)
export function Step4(p: StepProps) {
  const f = p.draft.fields
  const d = p.disabled
  const isCommunity = f.plan_type === 'community_tour'
  const suggestion = p.calc.fitness_suggested
  return (
    <div className="grid gap-6 sm:grid-cols-2">
      <NumberField label="Max. Gehzeit pro Tag" step={0.5} value={f.max_walk_hours} disabled={d} suffix={<span className="text-sm">h</span>} onChange={(v) => p.setFields({ max_walk_hours: v })} />
      <NumberField label="Max. Strecke pro Tag" value={f.max_distance_km} disabled={d} suffix={<span className="text-sm">km</span>} onChange={(v) => p.setFields({ max_distance_km: v })} />
      <NumberField label="Max. Höhenmeter ↑ pro Tag" step={50} value={f.max_ascent} disabled={d} onChange={(v) => p.setFields({ max_ascent: v })} />
      <NumberField label="Max. Höhenmeter ↓ pro Tag" step={50} value={f.max_descent} disabled={d} onChange={(v) => p.setFields({ max_descent: v })} />
      <RadioField<Fitness> label="Kondition" value={f.fitness} options={opts(FITNESS_LABELS)} disabled={d} missing={p.missing.has('fitness')}
        hint={suggestion && f.fitness && suggestion !== f.fitness ? `Nach Gehzeit und Höhenmetern passt eher „${FITNESS_LABELS[suggestion]}“.` : undefined}
        onChange={(v) => p.setFields({ fitness: v })} />
      <RadioField<Technique> label="Technik" value={f.technique} disabled={d} missing={p.missing.has('technique')}
        options={(Object.keys(TECHNIQUE_LABELS) as Technique[]).map((t) => ({ value: t, label: TECHNIQUE_LABELS[t], hint: TECHNIQUE_HINTS[t] }))}
        onChange={(v) => p.setFields({ technique: v })} />
      <TextField className="sm:col-span-2" label="Schwierigkeitsangabe der Sportart" hint="z. B. „T3, UIAA II, Klettersteig C, Hochtour WS“" value={f.grade} disabled={d} onChange={(v) => p.setFields({ grade: v })} />
      <AreaField className="sm:col-span-2" label="Voraussetzungen" value={f.requirements} disabled={d} missing={p.missing.has('requirements')} onChange={(v) => p.setFields({ requirements: v })} />
      <AreaField className="sm:col-span-2" label="Ausrüstung" value={f.equipment} disabled={d} missing={p.missing.has('equipment')} onChange={(v) => p.setFields({ equipment: v })} />
      <div className="flex flex-col gap-3 sm:col-span-2">
        <CheckField label="Ausnahme: auch Nichtmitglieder zulassen (Standard: nur DAV-Mitglieder)" checked={f.non_members_allowed} disabled={d}
          onChange={(v) => p.setFields({ non_members_allowed: v })} />
        {f.non_members_allowed && !isCommunity && (
          <TextField label="Begründung der Ausnahme und Rücksprache" value={f.non_members_reason} disabled={d} missing={p.missing.has('non_members_reason')}
            onChange={(v) => p.setFields({ non_members_reason: v })} />
        )}
      </div>
    </div>
  )
}

// Schritt 5 „Teilnahme“
export function Step5(p: StepProps) {
  const f = p.draft.fields
  const d = p.disabled
  return (
    <div className="grid gap-6 sm:grid-cols-2">
      <NumberField label="Min. Teilnehmende" min={1} value={f.min_participants} disabled={d} missing={p.missing.has('min_participants')} onChange={(v) => p.setFields({ min_participants: v })} />
      <NumberField label="Max. Teilnehmende" min={1} value={f.max_participants} disabled={d} missing={p.missing.has('max_participants')} onChange={(v) => p.setFields({ max_participants: v })} />
      <TextField label="Anmeldeschluss" type="date" value={f.registration_deadline} disabled={d} missing={p.missing.has('registration_deadline')} onChange={(v) => p.setFields({ registration_deadline: v })} />
      <SelectField label="Warteliste" value={f.waitlist ? 'ja' : 'nein'} options={[{ value: 'ja', label: 'ja, aktivieren' }, { value: 'nein', label: 'nein' }]} disabled={d}
        onChange={(v) => p.setFields({ waitlist: v !== 'nein' })} />
      <p className="text-sm text-muted-foreground sm:col-span-2">Zahlungsart: Onlinezahlung bei der Buchung.</p>
      <TextField className="sm:col-span-2" label="Stornobedingungen der Unterkunft (intern)" value={f.accommodation_cancellation} disabled={d}
        onChange={(v) => p.setFields({ accommodation_cancellation: v })} />
      <fieldset className="flex flex-col gap-2 sm:col-span-2" disabled={d}>
        <legend className="mb-2 text-sm font-medium">Fragen im Anmeldeformular</legend>
        <div className="grid gap-2 sm:grid-cols-2">
          {REGISTRATION_QUESTIONS.map((q) => (
            <CheckField key={q.value} label={q.label} checked={f.registration_questions.includes(q.value)}
              onChange={(on) => p.setFields({ registration_questions: on ? [...f.registration_questions, q.value] : f.registration_questions.filter((x) => x !== q.value) })} />
          ))}
        </div>
      </fieldset>
      <TextField className="sm:col-span-2" label="Weitere Frage" value={f.custom_question} disabled={d} onChange={(v) => p.setFields({ custom_question: v })} />
    </div>
  )
}

const QUICK: Partial<Record<CostGroup, { label: string; make: (p: StepProps) => Cost }[]>> = {
  leader: [
    { label: '+ PKW-Fahrt', make: (p) => ({ cost_group: 'leader', label: 'PKW-Fahrt hin und zurück (km)', quantity: 0, unit_price: rateValue(p.rates, 'rKm') ?? 0, is_car: true, is_overnight: false, is_hut_half_board: false }) },
    { label: '+ Übernachtung', make: (p) => ({ cost_group: 'leader', label: 'Übernachtung (Nächte)', quantity: Math.max(p.calc.days - 1, 1), unit_price: 0, is_car: false, is_overnight: true, is_hut_half_board: false }) },
    { label: '+ Pauschale Sulzenauhütte', make: (p) => ({ cost_group: 'leader', label: 'Fahrtpauschale Sulzenauhütte', quantity: 1, unit_price: rateValue(p.rates, 'rSH') ?? 0, is_car: false, is_overnight: false, is_hut_half_board: false }) },
    { label: '+ Pauschale Karl-Stein-Hütte', make: (p) => ({ cost_group: 'leader', label: 'Fahrtpauschale Karl-Stein-Hütte', quantity: 1, unit_price: rateValue(p.rates, 'rKSH') ?? 0, is_car: false, is_overnight: false, is_hut_half_board: false }) },
  ],
  self_paid: [
    { label: '+ Hütte Ü+HP', make: (p) => ({ cost_group: 'self_paid', label: 'Übernachtung (Lager) und Halbpension auf der Hütte, Mitglieder', quantity: Math.max(p.calc.days - 1, 1), unit_price: 63.5, is_car: false, is_overnight: false, is_hut_half_board: true }) },
    { label: '+ Getränke, Dusche, Abgaben', make: (p) => ({ cost_group: 'self_paid', label: 'Getränke, Dusche, Nächtigungsabgabe', quantity: Math.max(p.calc.days, 1), unit_price: 15, is_car: false, is_overnight: false, is_hut_half_board: false }) },
  ],
}

function CostTable({ p, group }: { p: StepProps; group: CostGroup }) {
  const d = p.disabled
  const rows = p.draft.costs.map((c, i) => ({ c, i })).filter((x) => x.c.cost_group === group)
  function setCosts(fn: (c: Cost[]) => Cost[]) {
    p.setDraft((x) => ({ ...x, costs: fn(x.costs) }))
  }
  function setCost(i: number, patch: Partial<Cost>) {
    setCosts((c) => c.map((x, j) => (j === i ? { ...x, ...patch } : x)))
  }
  const total = rows.reduce((s, { c }) => s + c.quantity * c.unit_price, 0)
  return (
    <Section title={COST_GROUP_LABELS[group]}>
      <div className="flex flex-col gap-2">
        {rows.map(({ c, i }) => (
          <div key={i} className="grid items-center gap-2 rounded-lg border p-2 sm:grid-cols-[2fr_0.6fr_0.8fr_0.8fr_auto]">
            <Input aria-label="Position" value={c.label} disabled={d} onChange={(e) => setCost(i, { label: e.target.value })} />
            <Input aria-label="Menge" type="number" min={0} step="any" className="tabular-nums" value={c.quantity} disabled={d} onChange={(e) => setCost(i, { quantity: Number(e.target.value) || 0 })} />
            <Input aria-label={group === 'self_paid' ? 'ca. € je Einheit' : 'Einzelpreis €'} type="number" min={0} step="0.01" className="tabular-nums" value={c.unit_price} disabled={d}
              onChange={(e) => setCost(i, { unit_price: Number(e.target.value) || 0 })} />
            <span className="text-right text-sm tabular-nums">{formatMoney(c.quantity * c.unit_price)}</span>
            <div className="flex items-center justify-end gap-1">
              {group === 'leader' && (
                <>
                  <CheckField label="PKW" checked={c.is_car} disabled={d} onChange={(v) => setCost(i, { is_car: v })} />
                  <CheckField label="Übernachtung" checked={c.is_overnight} disabled={d} onChange={(v) => setCost(i, { is_overnight: v })} />
                </>
              )}
              {group === 'self_paid' && (
                <CheckField label="Hütte mit HP" checked={c.is_hut_half_board} disabled={d} onChange={(v) => setCost(i, { is_hut_half_board: v })} />
              )}
              {!d && (
                <Button variant="ghost" size="icon" aria-label="Zeile entfernen" onClick={() => setCosts((x) => x.filter((_, j) => j !== i))}>
                  <Trash2Icon aria-hidden="true" />
                </Button>
              )}
            </div>
          </div>
        ))}
      </div>
      <div className="flex flex-wrap items-center justify-between gap-2">
        {!d && (
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" size="sm" onClick={() => setCosts((x) => [...x, { cost_group: group, label: '', quantity: 1, unit_price: 0, is_car: false, is_overnight: false, is_hut_half_board: false }])}>
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Zeile
            </Button>
            {(QUICK[group] ?? []).map((q) => (
              <Button key={q.label} variant="outline" size="sm" onClick={() => setCosts((x) => [...x, q.make(p)])}>
                {q.label}
              </Button>
            ))}
          </div>
        )}
        <span className="text-sm font-medium tabular-nums">Summe {formatMoney(total)}{group === 'per_participant' ? ' je TN' : group === 'self_paid' ? ' ca. je TN' : ''}</span>
      </div>
    </Section>
  )
}

// Schritt 6 „Kalkulation“ (R1–R4, R22; US-TK-06 bis -12, -19)
export function Step6(p: StepProps) {
  const f = p.draft.fields
  const d = p.disabled
  const c = p.calc
  const isCourse = f.plan_type === 'course'
  const isCommunity = f.plan_type === 'community_tour'
  const freeAllowed = !isCommunity && c.days === 1 && f.target_groups.includes('Familienwanderungen')
  const hasCar = p.draft.costs.some((x) => x.cost_group === 'leader' && x.is_car)
  const helpers = p.draft.leaders.filter((l) => l.rate_kind !== 'trainer').length
  const rateKeys = Object.keys(p.rates).sort()
  const validFrom = rateKeys.reduce<string | null>((m, k) => (!m || p.rates[k].valid_from > m ? p.rates[k].valid_from : m), null)
  return (
    <div className="flex flex-col gap-8">
      {isCommunity && (
        <p className="rounded-xl bg-muted p-4 text-sm">
          Gemeinschaftstour: kein Teilnahmebeitrag, keine Vergütung und keine Erstattung durch die Sektion. Die Organisationspauschale
          trägt die Sektion. Gib unten nur an, welche Kosten die Teilnehmenden selbst tragen.
        </p>
      )}
      <Section title="Vergütung der Leitung" description={isCourse ? 'Kurse nach Lehreinheiten (1 Stunde), auch mehrtägig; Helfende erhalten keine Vergütung.' : 'Abrechnungszeitraum ab Startort; An- und Abreisetage ggf. selbst abziehen.'}>
        <div className="grid gap-6 sm:grid-cols-3">
          {isCourse && (
            <SuggestedNumber label="Lehreinheiten à 1 h" value={f.teaching_hours} suggestion={c.suggestions.teaching_hours} touched={f.touched.includes('teaching_hours') || c.suggestions.teaching_hours === null}
              disabled={d} missing={p.missing.has('teaching_hours')} hint={c.days > 1 ? 'Bei mehrtägigen Kursen bitte selbst eintragen.' : undefined}
              onChange={(v) => touch(p, 'teaching_hours', v)} onReset={() => untouch(p, 'teaching_hours')} />
          )}
          {!isCourse && !isCommunity && (
            <>
              <SuggestedNumber label="Tagessätze (ab 8 h)" value={f.days_full} suggestion={c.suggestions.days_full} touched={f.touched.includes('days_full')}
                disabled={d} onChange={(v) => touch(p, 'days_full', v)} onReset={() => untouch(p, 'days_full')} />
              <SuggestedNumber label="Halbtagessätze (unter 8 h)" value={f.days_half} suggestion={c.suggestions.days_half} touched={f.touched.includes('days_half')}
                disabled={d} onChange={(v) => touch(p, 'days_half', v)} onReset={() => untouch(p, 'days_half')} />
            </>
          )}
          {!isCourse && (
            <SuggestedNumber label="Tage Organisationspauschale" value={f.org_days} suggestion={c.suggestions.org_days} touched={f.touched.includes('org_days')}
              disabled={d} onChange={(v) => touch(p, 'org_days', v)} onReset={() => untouch(p, 'org_days')} />
          )}
        </div>
        {helpers > 0 && !isCommunity && (
          <p className="text-sm text-muted-foreground">
            {helpers} Person(en) {helpers === 1 ? 'wird' : 'werden'} mit dem Helfersatz gerechnet (Rolle Helfer:in oder keine gültige Lizenz)
            {isCourse ? ' und bei Kursen nicht vergütet' : ''}.
          </p>
        )}
        <p className="text-sm">
          Vergütung {formatMoney(c.fee_total)} · Organisationspauschale {formatMoney(c.org_total)}
        </p>
      </Section>

      {!isCommunity && <CostTable p={p} group="leader" />}
      {!isCommunity && hasCar && (
        <TextField label="Begründung für die PKW-Fahrt" value={f.car_reason} disabled={d} missing={p.missing.has('car_reason')} onChange={(v) => p.setFields({ car_reason: v })} />
      )}
      {!isCommunity && <CostTable p={p} group="fixed" />}
      {!isCommunity && <CostTable p={p} group="per_participant" />}
      <CostTable p={p} group="self_paid" />

      {!isCommunity && (
        <Section title="Teilnahmebeitrag">
          {freeAllowed && (
            <CheckField label="Ohne Teilnahmebeitrag (Familienwanderung als Tagestour)" checked={f.no_fee} disabled={d} onChange={(v) => p.setFields({ no_fee: v })} />
          )}
          {c.is_free ? (
            <p className="text-sm">Ohne Teilnahmebeitrag trägt die Sektion {formatMoney(c.section_bears)}.</p>
          ) : (
            <>
              <div className="grid gap-6 sm:grid-cols-2">
                <NumberField label="Beitrag DAV-Mitglieder (€)" step={5} value={f.price_member} disabled={d}
                  hint={`Vorschlag ${formatMoney(c.price_suggested, true)}; leer = Vorschlag verwenden.`} onChange={(v) => p.setFields({ price_member: v })} />
                {f.non_members_allowed && (
                  <NumberField label="Beitrag Nichtmitglieder (€)" step={5} value={f.price_non_member} disabled={d}
                    hint={`Vorschlag ${formatMoney(c.price_non_member_suggested, true)}`} onChange={(v) => p.setFields({ price_non_member: v })} />
                )}
              </div>
              {c.fee_method && (
                <p className="text-xs text-muted-foreground">
                  Zahlungsgebühren gerechnet mit {PAYMENT_LABELS[c.fee_method] ?? c.fee_method} (teuerste aktive Zahlmethode, inkl. MwSt.).
                </p>
              )}
            </>
          )}
        </Section>
      )}

      <details className="rounded-xl border p-4 text-sm">
        <summary className="cursor-pointer font-medium">
          {p.detail.rates_frozen ? 'Satzstand eingefroren bei der Freigabe' : `Gerechnet mit Sätzen gültig ab ${validFrom ? formatDate(validFrom) : '–'}`}
        </summary>
        <ul className="mt-3 grid gap-1 sm:grid-cols-2">
          {rateKeys.map((k) => (
            <li key={k} className="flex justify-between gap-3">
              <span>{p.rates[k].label}</span>
              <span className="tabular-nums text-muted-foreground">
                {p.rates[k].value !== null ? Number(p.rates[k].value).toLocaleString('de-DE') : `${Number(p.rates[k].percent).toLocaleString('de-DE')} % + ${formatMoney(Number(p.rates[k].fixed))}${p.rates[k].active ? '' : ' (inaktiv)'}`}
              </span>
            </li>
          ))}
        </ul>
      </details>
    </div>
  )
}

// Schritt 7 „Einreichen“ (Bestätigungen c1–c4, Prototyp 6.1). Wortlaut c1 aus dem Prototyp (3.1); der Prototyp nennt für
// c2–c4 nur Kurzbezeichnungen, der ausgeschriebene Wortlaut ist [ANNAHME] (Abnahme, plan.md).
export function Step7(p: StepProps) {
  const f = p.draft.fields
  const d = p.disabled
  const isCommunity = f.plan_type === 'community_tour'
  return (
    <div className="flex flex-col gap-6">
      <RadioField label="Wer legt das Angebot in Yolawo an?" value={f.yolawo_by} options={opts(YOLAWO_LABELS)} disabled={d} onChange={(v) => p.setFields({ yolawo_by: v })} />
      <AreaField label="Hinweise für das Referat" value={f.notes_for_referat} disabled={d} onChange={(v) => p.setFields({ notes_for_referat: v })} />
      <div className="flex flex-col gap-3">
        {!isCommunity && (
          <>
            <CheckField label="Meine Qualifikation ist für diese Tour gültig. Lizenzmarke und Ausweiskopie liegen in der Geschäftsstelle." checked={f.confirm_license}
              disabled={d} missing={p.missing.has('confirm_license')} onChange={(v) => p.setFields({ confirm_license: v })} />
            <CheckField label="Die Kalkulation ist mit dem Referat abgestimmt; die Abrechnung erfolgt nach der Vergütungs- und Reisekostenordnung." checked={f.confirm_calculation}
              disabled={d} missing={p.missing.has('confirm_calculation')} onChange={(v) => p.setFields({ confirm_calculation: v })} />
            <CheckField label="Die Erklärung zur Übungsleiterpauschale liegt vor." checked={f.confirm_ul_declaration}
              disabled={d} missing={p.missing.has('confirm_ul_declaration')} onChange={(v) => p.setFields({ confirm_ul_declaration: v })} />
          </>
        )}
        <CheckField label="Ich führe die DAV-Notfallkarte mit (Notruf 112, danach DAV-Notfall-Hotline)." checked={f.confirm_emergency_card}
          disabled={d} missing={p.missing.has('confirm_emergency_card')} onChange={(v) => p.setFields({ confirm_emergency_card: v })} />
        <CheckField label="Nach der Tour einen Feedbackbogen senden" checked={f.feedback_form} disabled={d} onChange={(v) => p.setFields({ feedback_form: v })} />
      </div>
    </div>
  )
}
