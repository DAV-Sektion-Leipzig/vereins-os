// Einstieg der Edge Function ad-access; die Logik liegt in handler.ts (testbar ohne Supabase).
import { makeDeps } from '../_shared/db.ts'
import { handleAccess } from './handler.ts'

const deps = makeDeps()

Deno.serve((req) => handleAccess(req, deps))
