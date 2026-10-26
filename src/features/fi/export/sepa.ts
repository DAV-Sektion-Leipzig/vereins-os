// FT14 (US-FI-15, R26, R28, 01-erhebung.md C7): Überweisungsdatei pain.001.001.03 (SEPA-Überweisung) aus fi_payout_export.
// Reine Funktion ohne Browser-Abhängigkeit (Test: sepa.test.ts). Eine Zahlungsgruppe je Datei; kein BtchBookg,
// keine Adressen, keine Kategorie, kein BIC der Empfänger:innen (wie die Vorlage der Sparkasse).

export type PayoutExport = {
  run: {
    id: string
    year: number
    half: 1 | 2
    number: number
    execution_date: string
    msg_id: string
    pmt_inf_id: string
    line_count: number
    total: number
    released_at: string
    released_by_name: string | null
  }
  debtor: { debtor_name: string; iban: string; bic: string; ledger_account: string; valid_from: string } | null
  confirmations: { referat_name: string; name: string | null; date: string; is_substitute: boolean }[]
  lines: {
    sort_no: number
    last_name: string
    first_name: string
    amount: number
    group_label: string
    remittance: string
    end_to_end_id: string
    account_holder: string | null
    iban: string | null
    bank_changed: boolean
  }[]
}

/** Betrag in Cent (ganzzahlig, gegen Rundungsfehler beim Summieren). */
export function toCents(value: number | string): number {
  return Math.round(Number(value) * 100)
}

export function formatAmount(cents: number): string {
  return (cents / 100).toFixed(2)
}

// SEPA-Zeichensatz (EPC) und die Erweiterung der Deutschen Kreditwirtschaft (Umlaute, ß, &, *, $, %) [ANNAHME R26]
const ALLOWED = /[A-Za-z0-9/?:().,'+ \-ÄÖÜäöüß&*$%]/

/** Zeichen außerhalb des Zeichensatzes ersetzen: Akzente entfernen, sonst Leerzeichen; Länge begrenzen. */
export function sepaText(text: string, max: number): string {
  let out = ''
  for (const ch of text) {
    if (ALLOWED.test(ch)) out += ch
    else {
      const base = ch.normalize('NFKD').replace(/[̀-ͯ]/g, '')
      out += base && [...base].every((c) => ALLOWED.test(c)) ? base : ' '
    }
  }
  return [...out.replace(/\s+/g, ' ').trim()].slice(0, max).join('').trim()
}

export function xml(text: string): string {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/'/g, '&apos;').replace(/"/g, '&quot;')
}

export function compactIban(iban: string): string {
  return iban.replace(/\s+/g, '').toUpperCase()
}

/** Zeitpunkt der Freigabe als ISODateTime in Europe/Berlin mit Zeitzone, ohne Sekundenbruchteile. */
export function isoDateTimeBerlin(value: string): string {
  const date = new Date(value)
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Europe/Berlin',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    })
      .formatToParts(date)
      .map((p) => [p.type, p.value]),
  )
  const local = Date.UTC(+parts.year, +parts.month - 1, +parts.day, +parts.hour, +parts.minute, +parts.second)
  const offset = Math.round((local - Math.floor(date.getTime() / 1000) * 1000) / 60000)
  const sign = offset >= 0 ? '+' : '-'
  const hh = String(Math.floor(Math.abs(offset) / 60)).padStart(2, '0')
  const mm = String(Math.abs(offset) % 60).padStart(2, '0')
  return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}${sign}${hh}:${mm}`
}

/** Fehlende Angaben, ohne die keine Datei entstehen kann (Sektion bzw. Bankverbindung seit der Freigabe gelöscht). */
export function sepaProblems(data: PayoutExport): string[] {
  const problems: string[] = []
  if (!data.debtor?.debtor_name || !data.debtor.iban || !data.debtor.bic) {
    problems.push('Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren.')
  }
  for (const l of data.lines) {
    if (!l.iban || !l.account_holder) problems.push(`Bankverbindung fehlt: ${l.first_name} ${l.last_name}`)
  }
  return problems
}

export function buildPain001(data: PayoutExport): string {
  const debtor = data.debtor
  if (!debtor) throw new Error('debtor missing')
  const lines = [...data.lines].sort((a, b) => a.sort_no - b.sort_no)
  const total = lines.reduce((sum, l) => sum + toCents(l.amount), 0)
  const count = lines.length
  const tx = lines
    .map(
      (l) => `      <CdtTrfTxInf>
        <PmtId>
          <EndToEndId>${xml(l.end_to_end_id)}</EndToEndId>
        </PmtId>
        <Amt>
          <InstdAmt Ccy="EUR">${formatAmount(toCents(l.amount))}</InstdAmt>
        </Amt>
        <Cdtr>
          <Nm>${xml(sepaText(l.account_holder ?? '', 70))}</Nm>
        </Cdtr>
        <CdtrAcct>
          <Id>
            <IBAN>${xml(compactIban(l.iban ?? ''))}</IBAN>
          </Id>
        </CdtrAcct>
        <RmtInf>
          <Ustrd>${xml(sepaText(l.remittance, 140))}</Ustrd>
        </RmtInf>
      </CdtTrfTxInf>`,
    )
    .join('\n')

  return `<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.03" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.001.03 pain.001.001.03.xsd">
  <CstmrCdtTrfInitn>
    <GrpHdr>
      <MsgId>${xml(data.run.msg_id)}</MsgId>
      <CreDtTm>${isoDateTimeBerlin(data.run.released_at)}</CreDtTm>
      <NbOfTxs>${count}</NbOfTxs>
      <CtrlSum>${formatAmount(total)}</CtrlSum>
      <InitgPty>
        <Nm>${xml(sepaText(debtor.debtor_name, 70))}</Nm>
      </InitgPty>
    </GrpHdr>
    <PmtInf>
      <PmtInfId>${xml(data.run.pmt_inf_id)}</PmtInfId>
      <PmtMtd>TRF</PmtMtd>
      <NbOfTxs>${count}</NbOfTxs>
      <CtrlSum>${formatAmount(total)}</CtrlSum>
      <PmtTpInf>
        <SvcLvl>
          <Cd>SEPA</Cd>
        </SvcLvl>
      </PmtTpInf>
      <ReqdExctnDt>${data.run.execution_date}</ReqdExctnDt>
      <Dbtr>
        <Nm>${xml(sepaText(debtor.debtor_name, 70))}</Nm>
      </Dbtr>
      <DbtrAcct>
        <Id>
          <IBAN>${xml(compactIban(debtor.iban))}</IBAN>
        </Id>
      </DbtrAcct>
      <DbtrAgt>
        <FinInstnId>
          <BIC>${xml(debtor.bic.replace(/\s+/g, '').toUpperCase())}</BIC>
        </FinInstnId>
      </DbtrAgt>
${tx}
    </PmtInf>
  </CstmrCdtTrfInitn>
</Document>
`
}
