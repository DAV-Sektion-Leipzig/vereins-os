import type { ReactNode } from 'react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { cn } from '@/lib/utils'

// T070: Tabelle ab 640 px, darunter Karten (spec.md AD Abschnitt 6, DESIGN.md Layout).
export type Column<T> = {
  key: string
  header: ReactNode
  cell: (row: T) => ReactNode
  className?: string
  headerClassName?: string
}

type Props<T> = {
  rows: T[]
  rowKey: (row: T) => string
  columns: Column<T>[]
  /** Karte je Zeile für schmale Bildschirme. */
  card: (row: T) => ReactNode
  /** Leerer Zustand, wenn es keine Zeilen gibt. */
  empty: ReactNode
  caption?: string
}

export function ResponsiveTable<T>({ rows, rowKey, columns, card, empty, caption }: Props<T>) {
  if (rows.length === 0) {
    return <p className="text-sm text-muted-foreground">{empty}</p>
  }

  return (
    <>
      <div className="hidden overflow-hidden rounded-xl border sm:block">
        <Table>
          {caption && <caption className="sr-only">{caption}</caption>}
          <TableHeader>
            <TableRow className="bg-muted hover:bg-muted">
              {columns.map((c, i) => (
                <TableHead key={c.key} className={cn(i === 0 && 'pl-4', i === columns.length - 1 && 'pr-4', c.headerClassName)}>
                  {c.header}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((row) => (
              <TableRow key={rowKey(row)} className="last:border-0 hover:bg-transparent">
                {columns.map((c, i) => (
                  <TableCell key={c.key} className={cn(i === 0 && 'pl-4', i === columns.length - 1 && 'pr-4', c.className)}>
                    {c.cell(row)}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <ul className="flex flex-col gap-3 sm:hidden">
        {rows.map((row) => (
          <li key={rowKey(row)} className="flex flex-col gap-3 rounded-xl border p-4">
            {card(row)}
          </li>
        ))}
      </ul>
    </>
  )
}
