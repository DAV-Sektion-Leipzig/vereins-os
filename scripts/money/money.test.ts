// W-02: Betragseingaben – Punkt und Komma als Dezimaltrenner, Tausendertrenner abgelehnt.
import assert from 'node:assert/strict'
import { test } from 'node:test'
import { parseEuro } from '../../src/lib/money.ts'

test('Komma und Punkt als Dezimaltrenner', () => {
  assert.equal(parseEuro('12,50'), 12.5)
  assert.equal(parseEuro('12.50'), 12.5)
  assert.equal(parseEuro('12,5'), 12.5)
  assert.equal(parseEuro('12'), 12)
  assert.equal(parseEuro('0,99'), 0.99)
})

test('Leerzeichen und Eurozeichen', () => {
  assert.equal(parseEuro(' 7 € '), 7)
  assert.equal(parseEuro('7€'), 7)
  assert.equal(parseEuro('12,50 €'), 12.5)
})

test('Tausendertrenner und zu viele Nachkommastellen abgelehnt', () => {
  assert.equal(parseEuro('1.250'), null)
  assert.equal(parseEuro('1.234,56'), null)
  assert.equal(parseEuro('1,234.56'), null)
  assert.equal(parseEuro('12,345'), null)
  assert.equal(parseEuro('12345678'), null)
})

test('Minus nur mit allowNegative', () => {
  assert.equal(parseEuro('-5'), null)
  assert.equal(parseEuro('-5', { allowNegative: true }), -5)
  assert.equal(parseEuro('-5,25', { allowNegative: true }), -5.25)
})

test('Ungültige und leere Eingaben', () => {
  assert.equal(parseEuro('abc'), null)
  assert.equal(parseEuro(''), null)
  assert.equal(parseEuro('   '), null)
  assert.equal(parseEuro('€'), null)
  assert.equal(parseEuro('12,'), null)
  assert.equal(parseEuro(',50'), null)
  assert.equal(parseEuro('1e3'), null)
})
