// Einstieg der Edge Function sc-send; die Logik liegt in handler.ts (testbar ohne Supabase).
import { makeScDeps } from './deps.ts'
import { handleSend } from './handler.ts'

const deps = makeScDeps()

Deno.serve((req) => handleSend(req, deps))
