// Erster Seitenaufbau, solange Sitzung und eigene Person geladen werden (HydrateFallback).
export function LoadingScreen() {
  return (
    <div role="status" className="flex min-h-svh items-center justify-center border-t-3 border-t-brand-band px-6">
      <p className="text-sm text-muted-foreground">Wird geladen …</p>
    </div>
  )
}
