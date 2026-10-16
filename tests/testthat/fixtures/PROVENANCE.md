# Recorded-real fixtures — provenance manifest

These fixtures are **recorded-real** responses captured once from the live
Binance public REST API and replayed offline by the oracle tests
(`test-catalogue-diff.R`, `test-properties-recorded.R`). They are **not**
hand-authored: a hand-authored fixture that returns success for any input is the
circular mock that hides external-fact drift (the failure that let
`MIN_NOTIONAL` pass the tests until a check against the live API caught it). Each file's hash is asserted in its oracle test, so
a silent re-record is a visible diff.

To re-capture, run `data-raw/record_fixtures.R` and update `captured_on` + the
hashes below (and the `md5` literals asserted in `test-properties-recorded.R` +
the guard hash in `test-catalogue-diff.R`).

| fixture | source_url | captured_on | tool | sha256 | md5 | redaction |
|---|---|---|---|---|---|---|
| `binance_exchangeInfo_BTCUSDT.json` | `https://api.binance.com/api/v3/exchangeInfo?symbol=BTCUSDT` | 2026-09-25 | httr2 | `c277269808369aef5bfee7644d82c1dd78a3023d0b8fec6dada8dfea12624d50` | `bdeb13b0fecd7b5ba9905ea15fb530c5` | none (public market metadata) |
| `binance_exchangeInfo_multi.json` | `https://api.binance.com/api/v3/exchangeInfo?symbols=["BTCUSDT","ETHUSDT","BNBUSDT","SOLUSDT"]` | 2026-09-25 | httr2 | `62e63e3cb3f1128ab0eb57fa49a1bb23b10d2630e50001462a1130508a05a3ca` | `3380ecfd0eedc78177700444d3d70d67` | none (public market metadata) |
| `binance_klines_BTCUSDT_1d.json` | `https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=2` | 2026-09-25 | httr2 | `3af1985896564d2e5f10c4497c82ec546ff993d263c31aeb1ba08226e4caab91` | `ebd3fb59717da6bdc5e81cb53073bfa4` | none (public market data) |
| `binance_depth_BTCUSDT.json` | `https://api.binance.com/api/v3/depth?symbol=BTCUSDT&limit=5` | 2026-09-25 | httr2 | `c5dbfca399ba7642cd8c2741bd2c2ae9b230af2df8ecf193777f9f288a6e0cd3` | `40b2f075f1f16141a28c7ecaefd933db` | none (public market data) |
| `binance_ticker24hr_BTCUSDT.json` | `https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT` | 2026-09-25 | httr2 | `2f76362459baebd91cff60ed37774d305888ffb51fa7c360b9b5df8e4cdaa8ac` | `c5002f2d23db62fee5ac7f5d8c295f03` | none (public market data) |

Notes:

- The `sha256` is the canonical hash, recorded here for external /
  human verification; the property test asserts the base-R `tools::md5sum()`
  `md5` (no added dependency, runs everywhere) as the in-test tamper-evidence.
- The captured `/exchangeInfo` responses (single and multi-symbol) carry the
  **`NOTIONAL`** filter — Binance spot's current minimum-notional filter — and
  **no `MIN_NOTIONAL`** (the legacy name). This grounds the `MIN_NOTIONAL` correction:
  the connector's asserted belief now matches the authority, and the property
  test fails loudly if a re-record ever reintroduces the legacy name.
- The multi-symbol catalogue grounds the filters (tick size, lot size, minimum
  notional) and currencies of all four core symbols (`BTCUSDT`, `ETHUSDT`,
  `BNBUSDT`, `SOLUSDT`) against the live catalogue in one capture.
- `binance_depth_BTCUSDT.json` is a top-of-book order book (`bids` / `asks`
  price/qty ladders); `binance_ticker24hr_BTCUSDT.json` is the 24-hour
  rolling-window statistics. Both ground their column-semantics fact families.
- No credentials, no account data, no PII: these are anonymous public
  market-metadata / market-data endpoints (no API key required).
- These fixtures are **volatile** (a live exchange surface): the
  re-grounding window is 90 days from `captured_on`. Re-run
  `data-raw/record_fixtures.R` before the window lapses.
