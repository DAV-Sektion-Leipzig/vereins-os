// Daten der Seite „Schnittstellen“ (spec.md SC v0.2 Abschnitte 2, 6): Lesen über RLS, Schreiben nur über Funktionen.
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { callFunction } from '@/lib/functions'
import { hasLevel, requireLevel } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type ConnectionState = 'disabled' | 'active' | 'disturbed' | 'expired'
export type OutboxState = 'waiting' | 'sent' | 'failed' | 'discarded'
export type LogKind =
  | 'connection_created' | 'connection_changed' | 'key_changed' | 'state_changed' | 'modules_changed'
  | 'template_changed' | 'test' | 'send' | 'enqueue_rejected' | 'retry' | 'discard' | 'limit_reached'
export type LogResult = 'ok' | 'error' | 'rejected'

export const STATE_LABELS: Record<ConnectionState, string> = {
  active: 'aktiv',
  disabled: 'abgeschaltet',
  disturbed: 'gestört',
  expired: 'abgelaufen',
}

export const OUTBOX_LABELS: Record<OutboxState, string> = {
  waiting: 'wartet',
  sent: 'versendet',
  failed: 'fehlgeschlagen',
  discarded: 'verworfen',
}

export const LOG_KIND_LABELS: Record<LogKind, string> = {
  connection_created: 'Anbindung angelegt',
  connection_changed: 'Anbindung geändert',
  key_changed: 'Key gewechselt',
  state_changed: 'Zustand geändert',
  modules_changed: 'Module freigegeben',
  template_changed: 'Vorlage geändert',
  test: 'Test-E-Mail',
  send: 'Versand',
  enqueue_rejected: 'abgelehnt',
  retry: 'erneut senden',
  discard: 'verworfen',
  limit_reached: 'Grenze erreicht',
}

export const LOG_RESULT_LABELS: Record<LogResult, string> = { ok: 'erfolgreich', error: 'Fehler', rejected: 'abgelehnt' }

export const KIND_LABELS: Record<string, string> = { email_brevo: 'E-Mail (Brevo)' }

export type Connection = {
  id: string
  kind: string
  name: string
  state: ConnectionState
  sender_email: string
  sender_name: string
  key_last4: string | null
  key_expires_on: string | null
  key_changed_at: string | null
  last_success_at: string | null
  last_error_at: string | null
  last_error: string | null
  hourly_limit: number
  daily_limit: number
  modules: string[]
  sentToday: number
}

export type ModuleOption = { code: string; name: string }

export type StatusHint = { kind: string; amount: number; message: string }

export type ConnectionsData = { connections: Connection[]; modules: ModuleOption[]; hints: StatusHint[]; failed: boolean }

function dayStartIso(): string {
  const now = new Date()
  return new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString()
}

export async function loadHints(): Promise<StatusHint[]> {
  const { data, error } = await supabase.rpc('sc_status')
  return error || !Array.isArray(data) ? [] : (data as StatusHint[])
}

export async function loadConnections(): Promise<ConnectionsData> {
  await requireLevel('SC', 'read')
  const [connections, freigaben, modules, sent, hints] = await Promise.all([
    supabase
      .from('sc_connections')
      .select('id, kind, name, state, sender_email, sender_name, key_last4, key_expires_on, key_changed_at, last_success_at, last_error_at, last_error, hourly_limit, daily_limit')
      .order('name'),
    supabase.from('sc_connection_modules').select('connection_id, module_code'),
    supabase.from('ad_modules').select('code, name').order('sort_order'),
    supabase.from('sc_outbox').select('connection_id').eq('state', 'sent').gte('sent_at', dayStartIso()),
    loadHints(),
  ])
  if (connections.error || freigaben.error || modules.error || sent.error) {
    return { connections: [], modules: [], hints: [], failed: true }
  }
  const rows = connections.data as Omit<Connection, 'modules' | 'sentToday'>[]
  const links = freigaben.data as { connection_id: string; module_code: string }[]
  const sentRows = sent.data as { connection_id: string | null }[]
  return {
    connections: rows.map((c) => ({
      ...c,
      modules: links.filter((l) => l.connection_id === c.id).map((l) => l.module_code),
      sentToday: sentRows.filter((s) => s.connection_id === c.id).length,
    })),
    modules: modules.data as ModuleOption[],
    hints,
    failed: false,
  }
}

export type ConnectionInput = {
  id: string | null
  name: string
  sender_email: string
  sender_name: string
  key_expires_on: string | null
  hourly_limit: number
  daily_limit: number
}

export async function saveConnection(input: ConnectionInput) {
  return supabase.rpc('sc_save_connection', {
    p_id: input.id,
    p_kind: 'email_brevo',
    p_name: input.name,
    p_sender_email: input.sender_email,
    p_sender_name: input.sender_name,
    p_key_expires_on: input.key_expires_on,
    p_hourly_limit: input.hourly_limit,
    p_daily_limit: input.daily_limit,
  })
}

export async function setKey(id: string, key: string, expiresOn: string | null) {
  return supabase.rpc('sc_set_key', { p_id: id, p_key: key, p_expires_on: expiresOn })
}

export async function setState(id: string, state: 'active' | 'disabled') {
  return supabase.rpc('sc_set_state', { p_id: id, p_state: state })
}

export async function setModules(id: string, modules: string[]) {
  return supabase.rpc('sc_set_modules', { p_id: id, p_modules: modules })
}

/** Test-E-Mail an die eigene Login-Adresse über die Edge Function sc-send (US-SC-03). */
export async function sendTestMail(connectionId: string) {
  return callFunction<{ ok: boolean; message: string | null }>('sc-send', { connection_id: connectionId })
}

// Vorlagen (US-SC-07)
export type Occasion = {
  code: string
  module_code: string
  name: string
  description: string
  placeholders: string[]
  link_path: string
  updated_at: string
  subject: string | null
  body: string | null
}

export type OccasionsData = { occasions: Occasion[]; failed: boolean }

export async function loadOccasions(): Promise<OccasionsData> {
  await requireLevel('SC', 'read')
  const canEdit = await hasLevel('SC', 'edit')
  const [occasions, texts] = await Promise.all([
    supabase.from('sc_mail_occasions').select('code, module_code, name, description, placeholders, link_path, updated_at').order('module_code').order('name'),
    canEdit ? supabase.rpc('sc_occasion_texts') : Promise.resolve({ data: [], error: null }),
  ])
  if (occasions.error || texts.error) return { occasions: [], failed: true }
  const textRows = (texts.data ?? []) as { code: string; subject: string; body: string }[]
  return {
    occasions: (occasions.data as Omit<Occasion, 'subject' | 'body'>[]).map((o) => {
      const t = textRows.find((r) => r.code === o.code)
      return { ...o, subject: t?.subject ?? null, body: t?.body ?? null }
    }),
    failed: false,
  }
}

export async function saveOccasion(code: string, subject: string, body: string) {
  return supabase.rpc('sc_save_occasion', { p_code: code, p_subject: subject, p_body: body })
}

export async function previewOccasion(code: string, subject: string, body: string) {
  return supabase.rpc('sc_preview_occasion', { p_code: code, p_subject: subject, p_body: body })
}

// Postausgang (US-SC-10)
export type OutboxRow = {
  id: string
  occasion_code: string
  module_code: string
  recipient_email: string
  state: OutboxState
  attempts: number
  last_error: string | null
  created_at: string
  sent_at: string | null
}

export type OutboxFilter = { state: string; module: string; occasion: string; from: string; to: string }

export type OutboxData = {
  rows: OutboxRow[]
  total: number
  page: number
  filter: OutboxFilter
  occasions: { code: string; name: string; module_code: string }[]
  failed: boolean
}

function filterFrom(url: URL): OutboxFilter {
  const p = url.searchParams
  return { state: p.get('zustand') ?? '', module: p.get('modul') ?? '', occasion: p.get('anlass') ?? '', from: p.get('von') ?? '', to: p.get('bis') ?? '' }
}

function pageFrom(url: URL): number {
  const raw = Number.parseInt(url.searchParams.get('seite') ?? '1', 10)
  return Number.isFinite(raw) && raw > 0 ? raw : 1
}

/** Ende des Tages „bis“ (lokale Zeit) als ISO-Zeitpunkt. */
function endOfDay(day: string): string {
  const [y, m, d] = day.split('-').map(Number)
  return new Date(y, m - 1, d + 1).toISOString()
}

function startOfDay(day: string): string {
  const [y, m, d] = day.split('-').map(Number)
  return new Date(y, m - 1, d).toISOString()
}

export async function loadOutbox({ request }: LoaderFunctionArgs): Promise<OutboxData> {
  await requireLevel('SC', 'read')
  const url = new URL(request.url)
  const filter = filterFrom(url)
  const page = pageFrom(url)
  const from = (page - 1) * PAGE_SIZE
  let query = supabase
    .from('sc_outbox')
    .select('id, occasion_code, module_code, recipient_email, state, attempts, last_error, created_at, sent_at', { count: 'exact' })
  if (filter.state) query = query.eq('state', filter.state)
  if (filter.module) query = query.eq('module_code', filter.module)
  if (filter.occasion) query = query.eq('occasion_code', filter.occasion)
  if (filter.from) query = query.gte('created_at', startOfDay(filter.from))
  if (filter.to) query = query.lt('created_at', endOfDay(filter.to))
  const [rows, occasions] = await Promise.all([
    query.order('created_at', { ascending: false }).range(from, from + PAGE_SIZE - 1),
    supabase.from('sc_mail_occasions').select('code, name, module_code').order('name'),
  ])
  if (rows.error || occasions.error) return { rows: [], total: 0, page, filter, occasions: [], failed: true }
  return {
    rows: rows.data as OutboxRow[],
    total: rows.count ?? 0,
    page,
    filter,
    occasions: occasions.data as { code: string; name: string; module_code: string }[],
    failed: false,
  }
}

export async function retryMail(id: string) {
  return supabase.rpc('sc_outbox_retry', { p_id: id })
}

export async function discardMail(id: string) {
  return supabase.rpc('sc_outbox_discard', { p_id: id })
}

export async function loadMailContent(id: string) {
  return supabase.rpc('sc_outbox_content', { p_id: id })
}

// Protokoll (US-SC-11)
export type LogRow = {
  id: number
  created_at: string
  connection_id: string | null
  module_code: string | null
  actor_user_id: string | null
  kind: LogKind
  result: LogResult
  message: string | null
}

export type LogFilter = { connection: string; kind: string; result: string; from: string; to: string }

export type LogData = {
  rows: LogRow[]
  total: number
  page: number
  filter: LogFilter
  connections: { id: string; name: string }[]
  actors: Record<string, string>
  failed: boolean
}

export async function loadLog({ request }: LoaderFunctionArgs): Promise<LogData> {
  await requireLevel('SC', 'read')
  const url = new URL(request.url)
  const p = url.searchParams
  const filter: LogFilter = { connection: p.get('anbindung') ?? '', kind: p.get('art') ?? '', result: p.get('ergebnis') ?? '', from: p.get('von') ?? '', to: p.get('bis') ?? '' }
  const page = pageFrom(url)
  const from = (page - 1) * PAGE_SIZE
  let query = supabase
    .from('sc_log')
    .select('id, created_at, connection_id, module_code, actor_user_id, kind, result, message', { count: 'exact' })
  if (filter.connection) query = query.eq('connection_id', filter.connection)
  if (filter.kind) query = query.eq('kind', filter.kind)
  if (filter.result) query = query.eq('result', filter.result)
  if (filter.from) query = query.gte('created_at', startOfDay(filter.from))
  if (filter.to) query = query.lt('created_at', endOfDay(filter.to))
  const [rows, connections] = await Promise.all([
    query.order('created_at', { ascending: false }).order('id', { ascending: false }).range(from, from + PAGE_SIZE - 1),
    supabase.from('sc_connections').select('id, name').order('name'),
  ])
  if (rows.error || connections.error) return { rows: [], total: 0, page, filter, connections: [], actors: {}, failed: true }
  const logRows = rows.data as LogRow[]
  // Namen der Ausführenden (sc_actor_names, nur mit SC ≥ lesen); ohne Treffer „Nutzer:in“
  const actorIds = [...new Set(logRows.map((r) => r.actor_user_id).filter((v): v is string => !!v))]
  const actors: Record<string, string> = {}
  if (actorIds.length) {
    const { data } = await supabase.rpc('sc_actor_names', { p_users: actorIds })
    for (const row of (data ?? []) as { user_id: string; name: string }[]) actors[row.user_id] = row.name
  }
  return { rows: logRows, total: rows.count ?? 0, page, filter, connections: connections.data as { id: string; name: string }[], actors, failed: false }
}
