import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import logoUrl from '@/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { MESSAGES } from '@/lib/errors'
import { supabase } from '@/lib/supabase'

// T097 (US-AD-04 AK1, R18): Link anfordern; die Bestätigung ist immer dieselbe, auch bei Fehlern.
export function PasswortVergessenPage() {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setPending(true)
    try {
      await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo: `${window.location.origin}/passwort-setzen` })
    } catch {
      // bewusst keine andere Meldung (R18)
    } finally {
      setPending(false)
      setSent(true)
    }
  }

  return (
    <main className="flex min-h-svh flex-col items-center justify-center gap-14 border-t-3 border-t-brand-band px-4 py-14">
      <img src={logoUrl} alt="DAV Sektion Leipzig" className="h-20 w-auto" />
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="text-lg">
            <h1>Passwort vergessen</h1>
          </CardTitle>
          <CardDescription>Wir schicken dir einen Link zum Zurücksetzen.</CardDescription>
        </CardHeader>
        <CardContent>
          {sent ? (
            <div className="flex flex-col gap-4">
              <p role="status" className="text-sm">
                {MESSAGES.resetRequested}
              </p>
              <Button variant="outline" asChild className="self-start">
                <Link to="/login">Zur Anmeldung</Link>
              </Button>
            </div>
          ) : (
            <form className="flex flex-col gap-4" onSubmit={onSubmit} noValidate>
              <div className="flex flex-col gap-2">
                <Label htmlFor="email">Login-Adresse</Label>
                <Input id="email" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} />
              </div>
              <Button type="submit" className="h-9" disabled={pending || !email.trim()}>
                {pending ? 'Wird gesendet …' : 'Link anfordern'}
              </Button>
              <Link to="/login" className="self-start text-sm text-primary underline-offset-4 hover:underline">
                Zurück zur Anmeldung
              </Link>
            </form>
          )}
        </CardContent>
      </Card>
    </main>
  )
}
