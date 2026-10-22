// Einstieg der Edge Function ad-invite; die Logik liegt in handler.ts (testbar ohne Supabase).
import { makeDeps } from '../_shared/db.ts'
import { handleInvite } from './handler.ts'

const deps = makeDeps()

Deno.serve((req) => handleInvite(req, deps))
