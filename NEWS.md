# bourse 0.0.0.9000 (development)

First development version. `bourse` is the market-data connector of the ORCHESTRA
analytics framework -- the trading-domain counterpart of `terroir` -- built with
the Independent Oracle Principle as a first-class constraint from day one.

## New features

* `bourse_ohlcv()` fetches or parses an OHLCV candle series and returns a
  grounded `market_series`, or a `bourse_refusal` when it will not stand behind
  the result (unknown source, malformed candles, missing HTTP backend).
* `bourse_external_facts()` and `bourse_fact_status()` expose the provenance
  registry: every asserted fact (symbol universe, tick size, lot size, minimum
  notional, fee schedule, currencies, timestamp convention, column semantics) is
  recorded with the date it was last diffed against the exchange, `NA` until
  grounded.
* `bourse_catalogue_diff()` is the grounding oracle: it diffs the asserted facts
  against the exchange's own `/exchangeInfo` catalogue and grounds those that
  agree with a real date -- the only operation that moves a fact from
  `[unverified]` to `grounded`.
* `grounding_grounded()`, `grounding_unverified()`, `combine_grounding()` are the
  canonical federation provenance tokens; `is_refusal()` and `fact_grounding()`
  are the gates a consumer reads before acting.

The live exchange path uses the suggested `httr2` + `jsonlite`; the parsing,
grounding, and refusal logic is exercised offline against recorded-real
catalogue and candle fixtures.

## External data contracts

* Recorded-real Binance cassettes (`tests/testthat/fixtures/binance_*BTCUSDT*.json`,
  captured 2026-06-11, hash-pinned in `fixtures/PROVENANCE.md`) now back the
  offline oracle: `test-catalogue-diff.R` replays a real `/exchangeInfo` response
  and `test-properties-recorded.R` asserts physical / structural invariants on it
  (the silent-escape schema / units facts). These replace the prior hand-authored
  fixtures -- the circular mock that let a stale filter name pass green.
* **Corrected the spot minimum-notional filter to `NOTIONAL`** -- Binance
  migrated it from the legacy `MIN_NOTIONAL`, and the live exchange exposes
  `NOTIONAL`. The catalogue diff accepts either for back-compat; the
  recorded-real property test fails loudly if a re-record reintroduces the
  legacy name.
* `.external_facts` is now the canonical recipe-52 registry (`family`, `kind`,
  `value`, `source`, `verified_on`, `reverify_by`, `oracle_types`, `signoff`),
  validated per-family by `.validate_external_registry()` (gate F13/F14). Seven
  fact families are grounded by the recorded-real cassette; `fee_schedule` is
  honestly reported `[unverified]` (its auth-gated `/sapi` endpoint is
  unimplemented).
* `data-raw/record_fixtures.R` re-captures the cassettes against the live
  authority and prints the new hashes (the recipe-52 re-grounding script).
