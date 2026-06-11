# Recorded-real fixtures — provenance manifest

These fixtures are **recorded-real** responses captured once from the live
Binance public REST API and replayed offline by the oracle tests
(`test-catalogue-diff.R`, `test-properties-recorded.R`). They are **not**
hand-authored: a hand-authored fixture that returns success for any input is the
circular mock that hides external-fact drift (recipe 52 §3, the failure that let
`MIN_NOTIONAL` ride green until the round-3 grounding audit caught it against the
live authority). Each file's hash is asserted in its oracle test, so a silent
re-record is a visible diff (the meta-oracle, recipe 52 §8).

To re-capture, run `data-raw/record_fixtures.R` and update `captured_on` + the
hashes below (and the `md5` literals asserted in `test-properties-recorded.R`).

| fixture | source_url | captured_on | tool | sha256 | md5 | redaction |
|---|---|---|---|---|---|---|
| `binance_exchangeInfo_BTCUSDT.json` | `https://api.binance.com/api/v3/exchangeInfo?symbol=BTCUSDT` | 2026-06-11 | curl | `6c2973ea021fa33bbfaaff064dfadc654a8ca0d6fcfd575b3edf54662974dd3d` | `9a468c45aa53a3a7783fc31b68ac5528` | none (public market metadata) |
| `binance_klines_BTCUSDT_1d.json` | `https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=2` | 2026-06-11 | curl | `daa16dd17aed3128c1c584b21092bf2460b805609f9f0c10b5ece4377267ac7d` | `2a99841bd15154e57ad1d0489e3cd702` | none (public market data) |

Notes:

- The `sha256` is the recipe-52 canonical hash, recorded here for external /
  human verification; the property test asserts the base-R `tools::md5sum()`
  `md5` (no added dependency, runs everywhere) as the in-test tamper-evidence.
- The captured `/exchangeInfo` response carries the **`NOTIONAL`** filter —
  Binance spot's current minimum-notional filter — and **no `MIN_NOTIONAL`**
  (the legacy name). This grounds the round-3 correction: the connector's
  asserted belief now matches the authority, and the property test fails loudly
  if a re-record ever reintroduces the legacy name.
- No credentials, no account data, no PII: these are anonymous public
  market-metadata endpoints (no API key required).
