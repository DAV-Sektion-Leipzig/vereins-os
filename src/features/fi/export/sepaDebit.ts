// FT24 (US-FI-19, R38, R40, R42, R43; 01-erhebung.md C11): Lastschriftdatei pain.008.001.02 (SEPA-Basislastschrift CORE)
// aus fi_collection_export, wie die Vorlage der Sparkasse: je Sequenz (FRST, RCUR) eine Zahlungsgruppe,
// DbtrAgt = NOTPROVIDED, kein BtchBookg, kein ChrgBr. Reine Funktion ohne Browser-Abhängigkeit (Test: sepaDebit.test.ts).
import { compactIban, formatAmount, isoDateTimeBerlin, sepaText, toCents, xml } from './sepa'

export type Sequence = 'FRST' | 'RCUR'

export type CollectionExport = {
  run: {
    id: string
    month: string
    number: number
    due_date: string
    msg_id: string
    pmt_inf_id_frst: string | null
    pmt_inf_id_rcur: string | null
    line_count: number
    total: number
    released_at: string
    released_by_name: string | null
  }
  creditor: {
    debtor_name: string
    iban: string
    bic: string
    ledger_account: string
    valid_from: string
    creditor_id: string | null
    ledger_account_collection: string | null
  } | null
  lines: {
    sort_no: number
    participant_first_name: string
    participant_last_name: string
    participant_preferred_name: string | null
    holder_name: string | null
    group_label: string
    mandate_reference: string
    mandate_signed_on: string
    sequence: Sequence
    monthly_amount: number
    extra_amount: number | null
    extra_text: string | null
    amount: number
    remittance: string
    end_to_end_id: string
    account_holder: string | null
    iban: string | null
    bank_changed: boolean
  }[]
}

/** Fehlende Angaben, ohne die keine Datei entstehen kann. */
export function debitProblems(data: CollectionExport): string[] {
  const problems: string[] = []
  const c = data.creditor
  if (!c?.debtor_name || !c.iban || !c.bic || !c.creditor_id) {
    problems.push('Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren.')
  }
  for (const l of data.lines) {
    if (!l.iban || !l.account_holder) problems.push(`Bankverbindung fehlt: ${l.participant_first_name} ${l.participant_last_name}`)
  }
  return problems
}

function paymentInfo(data: CollectionExport, sequence: Sequence, pmtInfId: string): string {
  const c = data.creditor!
  const lines = data.lines.filter((l) => l.sequence === sequence).sort((a, b) => a.sort_no - b.sort_no)
  const total = lines.reduce((s, l) => s + toCents(l.amount), 0)
  const tx = lines
    .map(
      (l) => `      <DrctDbtTxInf>
        <PmtId>
          <EndToEndId>${xml(l.end_to_end_id)}</EndToEndId>
        </PmtId>
        <InstdAmt Ccy="EUR">${formatAmount(toCents(l.amount))}</InstdAmt>
        <DrctDbtTx>
          <MndtRltdInf>
            <MndtId>${xml(l.mandate_reference)}</MndtId>
            <DtOfSgntr>${l.mandate_signed_on}</DtOfSgntr>
          </MndtRltdInf>
        </DrctDbtTx>
        <DbtrAgt>
          <FinInstnId>
            <Othr>
              <Id>NOTPROVIDED</Id>
            </Othr>
          </FinInstnId>
        </DbtrAgt>
        <Dbtr>
          <Nm>${xml(sepaText(l.account_holder ?? '', 70))}</Nm>
        </Dbtr>
        <DbtrAcct>
          <Id>
            <IBAN>${xml(compactIban(l.iban ?? ''))}</IBAN>
          </Id>
        </DbtrAcct>
        <RmtInf>
          <Ustrd>${xml(sepaText(l.remittance, 140))}</Ustrd>
        </RmtInf>
      </DrctDbtTxInf>`,
    )
    .join('\n')
  return `    <PmtInf>
      <PmtInfId>${xml(pmtInfId)}</PmtInfId>
      <PmtMtd>DD</PmtMtd>
      <NbOfTxs>${lines.length}</NbOfTxs>
      <CtrlSum>${formatAmount(total)}</CtrlSum>
      <PmtTpInf>
        <SvcLvl>
          <Cd>SEPA</Cd>
        </SvcLvl>
        <LclInstrm>
          <Cd>CORE</Cd>
        </LclInstrm>
        <SeqTp>${sequence}</SeqTp>
      </PmtTpInf>
      <ReqdColltnDt>${data.run.due_date}</ReqdColltnDt>
      <Cdtr>
        <Nm>${xml(sepaText(c.debtor_name, 70))}</Nm>
      </Cdtr>
      <CdtrAcct>
        <Id>
          <IBAN>${xml(compactIban(c.iban))}</IBAN>
        </Id>
      </CdtrAcct>
      <CdtrAgt>
        <FinInstnId>
          <BIC>${xml(c.bic.replace(/\s+/g, '').toUpperCase())}</BIC>
        </FinInstnId>
      </CdtrAgt>
      <CdtrSchmeId>
        <Id>
          <PrvtId>
            <Othr>
              <Id>${xml(c.creditor_id ?? '')}</Id>
              <SchmeNm>
                <Prtry>SEPA</Prtry>
              </SchmeNm>
            </Othr>
          </PrvtId>
        </Id>
      </CdtrSchmeId>
${tx}
    </PmtInf>`
}

export function buildPain008(data: CollectionExport): string {
  if (!data.creditor) throw new Error('creditor missing')
  const total = data.lines.reduce((s, l) => s + toCents(l.amount), 0)
  const groups: string[] = []
  for (const sequence of ['FRST', 'RCUR'] as Sequence[]) {
    if (!data.lines.some((l) => l.sequence === sequence)) continue
    const id = (sequence === 'FRST' ? data.run.pmt_inf_id_frst : data.run.pmt_inf_id_rcur) ?? `${data.run.msg_id}-${sequence}`
    groups.push(paymentInfo(data, sequence, id))
  }
  return `<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.001.02" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.008.001.02 pain.008.001.02.xsd">
  <CstmrDrctDbtInitn>
    <GrpHdr>
      <MsgId>${xml(data.run.msg_id)}</MsgId>
      <CreDtTm>${isoDateTimeBerlin(data.run.released_at)}</CreDtTm>
      <NbOfTxs>${data.lines.length}</NbOfTxs>
      <CtrlSum>${formatAmount(total)}</CtrlSum>
      <InitgPty>
        <Nm>${xml(sepaText(data.creditor.debtor_name, 70))}</Nm>
      </InitgPty>
    </GrpHdr>
${groups.join('\n')}
  </CstmrDrctDbtInitn>
</Document>
`
}
