import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import logoUrl from '@/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { MESSAGES } from '@/lib/errors'
import { supabase } from '@/lib/supabase'

// US-AD-02: Anmelden mit Login-Adresse und Passwort. Jeder Fehler zeigt dieselbe Meldung (R18).
export function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    setPending(true)
    try {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      })
      if (signInError) {
        setError(MESSAGES.loginFailed)
        return
      }
      navigate('/', { replace: true })
    } catch {
      setError(MESSAGES.loginFailed)
    } finally {
      setPending(false)
    }
  }

  return (
    <main className="flex min-h-svh flex-col items-center justify-center gap-10 border-t-3 border-t-brand-band px-4 py-8">
      <img src={logoUrl} alt="DAV Sektion Leipzig" className="h-20 w-auto" />
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="text-lg">Vereins OS</CardTitle>
          <CardDescription>Melde dich mit deiner Login-Adresse an.</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="flex flex-col gap-4" onSubmit={onSubmit} noValidate>
            <div className="flex flex-col gap-2">
              <Label htmlFor="email">Login-Adresse</Label>
              <Input
                id="email"
                type="email"
                autoComplete="username"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="password">Passwort</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
            </div>
            {error && (
              <p role="alert" className="text-sm text-destructive">
                {error}
              </p>
            )}
            <Button type="submit" size="lg" disabled={pending}>
              {pending ? 'Anmelden …' : 'Anmelden'}
            </Button>
            <Link to="/passwort-vergessen" className="text-sm text-muted-foreground underline-offset-4 hover:underline">
              Passwort vergessen
            </Link>
          </form>
        </CardContent>
      </Card>
    </main>
  )
}
