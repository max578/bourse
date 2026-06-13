# Recorded-real fixtures — provenance manifest

These fixtures are **recorded-real** responses captured once from the live
Binance public REST API and replayed offline by the oracle tests
(`test-catalogue-diff.R`, `test-properties-recorded.R`). They are **not**
hand-authored: a hand-authored fixture that returns success for any input is the
circular mock that hides external-fact drift (recipe 52 section 3, the failure
that let `MIN_NOTIONAL` ride green until the round-3 grounding audit caught it
against the live authority). Each file's hash is asserted in its oracle test, so
a silent re-record is a visible diff (the meta-oracle, recipe 52 section 8).

To re-capture, run `data-raw/record_fixtures.R` and update `captured_on` + the
hashes below (and the `md5` literals asserted in `test-properties-recorded.R` +
the guard hash in `test-catalogue-diff.R`).

| fixture | source_url | captured_on | tool | sha256 | md5 | redaction |
|---|---|---|---|---|---|---|
| `binance_exchangeInfo_BTCUSDT.json` | `https://api.binance.com/api/v3/exchangeInfo?symbol=BTCUSDT` | 2026-06-13 | httr2 | `62141b35758733b5fed50ddfdc957e682873ad810d013937985771b2db6be5c1` | `e6f23b4bd5f3d1a652fe21d6b35cc1b7` | none (public market metadata) |
| `binance_exchangeInfo_multi.json` | `https://api.binance.com/api/v3/exchangeInfo?symbols=["BTCUSDT","ETHUSDT","BNBUSDT","SOLUSDT"]` | 2026-06-13 | httr2 | `cea53b3d960accd0e3da73b7ee46214975634ce9be433811f9409fac916eaf81` | `da9eb072c62a39a7fcfa69078b606571` | none (public market metadata) |
| `binance_klines_BTCUSDT_1d.json` | `https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=2` | 2026-06-13 | httr2 | `b93ac1e38f66166492a7971bd1e97f0e5341cd0fbe3648513214140bcd80c65c` | `f3830885f9afa9555d39be6d201d3519` | none (public market data) |
| `binance_depth_BTCUSDT.json` | `https://api.binance.com/api/v3/depth?symbol=BTCUSDT&limit=5` | 2026-06-13 | httr2 | `20a44dd6b570e4ee9a1688e2208b559e45a3f61bc7ea0231eca906faf7233b13` | `be49abab6a4d68be4f2da38f27ad8caf` | none (public market data) |
| `binance_ticker24hr_BTCUSDT.json` | `https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT` | 2026-06-13 | httr2 | `007d8789b0ba4b94b58957783b5d41ed55d575a757965efa633068fa1f2e773e` | `2e0d75f3dedeb9802320b89c431ca6b8` | none (public market data) |

Notes:

- The `sha256` is the recipe-52 canonical hash, recorded here for external /
  human verification; the property test asserts the base-R `tools::md5sum()`
  `md5` (no added dependency, runs everywhere) as the in-test tamper-evidence.
- The captured `/exchangeInfo` responses (single and multi-symbol) carry the
  **`NOTIONAL`** filter — Binance spot's current minimum-notional filter — and
  **no `MIN_NOTIONAL`** (the legacy name). This grounds the round-3 correction:
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
- These fixtures are **volatile** (a live exchange surface): the recipe-52
  re-grounding window is 90 days from `captured_on`. Re-run
  `data-raw/record_fixtures.R` before the window lapses.
