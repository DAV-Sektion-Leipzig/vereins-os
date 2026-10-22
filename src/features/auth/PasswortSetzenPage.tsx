import { useState, type FormEvent } from 'react'
import { CircleAlertIcon } from 'lucide-react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import logoUrl from '@/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { MESSAGES } from '@/lib/errors'
import { supabase } from '@/lib/supabase'

// T096 (US-AD-03, US-AD-04): Passwort aus Einladungs- oder Reset-Link setzen (research.md R-04: token_hash).
// Der Link wird erst beim Speichern eingelöst, damit Vorab-Aufrufe durch Virenscanner ihn nicht verbrauchen.
export function PasswortSetzenPage() {
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const tokenHash = params.get('token_hash') ?? ''
  const type = params.get('type') === 'recovery' ? 'recovery' : 'invite'
  const invalidText = type === 'recovery' ? MESSAGES.recoveryLinkInvalid : MESSAGES.inviteLinkInvalid

  const [password, setPassword] = useState('')
  const [repeat, setRepeat] = useState('')
  const [error, setError] = useState<string | null>(tokenHash ? null : invalidText)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    // R19 vor dem Einlösen des Links
    if (password.length < 8) return setError(MESSAGES.passwordTooShort)
    if (password !== repeat) return setError(MESSAGES.passwordMismatch)
    setError(null)
    setPending(true)
    try {
      const verified = await supabase.auth.verifyOtp({ token_hash: tokenHash, type })
      if (verified.error) return setError(invalidText)
      const updated = await supabase.auth.updateUser({ password })
      if (updated.error) return setError(MESSAGES.unexpected)
      navigate('/', { replace: true })
    } catch {
      setError(MESSAGES.unexpected)
    } finally {
      setPending(false)
    }
  }

  return (
    <main className="flex min-h-svh flex-col items-center justify-center gap-14 border-t-3 border-t-brand-band px-4 py-14">
      <img src={logoUrl} alt="DAV Sektion Leipzig" className="h-20 w-auto" />
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="text-lg">
            <h1>{type === 'recovery' ? 'Neues Passwort setzen' : 'Zugang aktivieren'}</h1>
          </CardTitle>
          <CardDescription>Wähle ein Passwort mit mindestens 8 Zeichen.</CardDescription>
        </CardHeader>
        <CardContent>
          {!tokenHash ? (
            <div className="flex flex-col gap-4">
              <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
                <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
                {invalidText}
              </p>
              <Button variant="outline" asChild className="self-start">
                <Link to="/login">Zur Anmeldung</Link>
              </Button>
            </div>
          ) : (
            <form className="flex flex-col gap-4" onSubmit={onSubmit} noValidate>
              <div className="flex flex-col gap-2">
                <Label htmlFor="password">Passwort</Label>
                <Input id="password" type="password" autoComplete="new-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="password-repeat">Passwort wiederholen</Label>
                <Input id="password-repeat" type="password" autoComplete="new-password" required value={repeat} onChange={(e) => setRepeat(e.target.value)} />
              </div>
              {error && (
                <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
                  <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
                  {error}
                </p>
              )}
              <Button type="submit" className="h-9" disabled={pending}>
                {pending ? 'Speichern …' : 'Passwort speichern'}
              </Button>
            </form>
          )}
        </CardContent>
      </Card>
    </main>
  )
}
