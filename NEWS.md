# bourse (development version)

* The package has a logo.
* README carries status badges and lists related packages.
* CI runs lintr (report-only) and test coverage.

## Testing

* The recorded Binance responses were captured again on 2026-09-25, which
  restarts the 90-day re-grounding window. The asserted facts still match the
  new capture.

## Documentation

* Fixed a missing possessive in the package description ("the exchange own
  catalogue" -> "the exchange's own catalogue"), corrected on `DESCRIPTION`,
  the package-level roxygen block and `man/bourse-package.Rd`.
* Fixed a garbled, semicolon-spliced sentence in the *Getting started with
  bourse* vignette's opening section (the intended sense, already correct in
  `README.md`, is "a trading system that is risk control, not bookkeeping").
* Replaced stray Unicode en dashes and curly quotation marks in `README.md`
  with the house-style ASCII `--` and straight quotes (`README.Rmd`, the
  knitted source, was already clean).

# bourse 0.1.0

Broadens coverage from the single-symbol Binance-spot-OHLCV connector to a
multi-symbol connector with three read-only market-data verbs, while keeping the
Independent Oracle Principle (IOP) as a first-class constraint: every new
external fact is grounded against a recorded-real authority response before it is
trusted.

## New features

* `bourse_orderbook()` fetches or parses the top-of-book order book from
  `/api/v3/depth` and returns a grounded `order_book` (the `bids` / `asks`
  price/qty ladders), or a `bourse_refusal` -- including a refusal for a crossed
  book (best bid not below best ask), the structural impossibility that catches a
  transposed ladder.
* `bourse_ticker()` fetches or parses the 24-hour rolling-window statistics from
  `/api/v3/ticker/24hr` and returns a grounded `market_ticker`, or a refusal. Its
  validator rejects an inverted high/low envelope.
* Both verbs follow the established pattern: an offline parse path always
  available (pass the recorded payload), a live path Suggests-gated on `httr2` +
  `jsonlite`, an `obs_schema` describing each column's quantity and unit, and a
  grounding label combined worst-case from the facts the object rests on.

## Multi-symbol grounding

* `bourse_catalogue_diff()` now grounds the multi-symbol core universe
  (`BTCUSDT`, `ETHUSDT`, `BNBUSDT`, `SOLUSDT`) by default. Each requested
  symbol's filters (tick size, lot size, minimum notional) and currencies must
  agree with the catalogue for the corresponding family to ground; a single
  missing symbol leaves `symbol_universe` `[unverified]`, not silently grounded.

## External data contracts

* Two new fact families -- `orderbook_column_semantics` and
  `ticker_column_semantics` -- join the provenance registry, grounded by
  recorded-real property oracles on the captured depth and ticker payloads.
* The recorded-real cassettes were re-captured against the live Binance authority
  on 2026-06-13 (the re-grounding step, restarting the 90-day window),
  and a multi-symbol `/exchangeInfo` cassette was added. New cassettes:
  `binance_exchangeInfo_multi.json`, `binance_depth_BTCUSDT.json`,
  `binance_ticker24hr_BTCUSDT.json`. All are hash-pinned in
  `fixtures/PROVENANCE.md` (sha256 + md5) with the `md5` asserted in-test as the
  meta-oracle; a silent re-record fails loudly.
* `data-raw/record_fixtures.R` now captures all five cassettes (single- and
  multi-symbol catalogue, klines, depth, ticker) and prints their new hashes.

## Known gaps

* `fee_schedule` remains `[unverified]`. Its authority is the
  authenticated `/sapi/v1/asset/tradeFee` endpoint, which would introduce an API
  credential surface; it is deliberately not implemented (see `SECURITY.md`). The
  registry reports it `[unverified]` rather than substituting a documentation
  default it cannot diff against the account's actual fee tier.

## Release ceremony

* Added `inst/CITATION` (version read from package metadata),
  `CONTRIBUTING.md`, `SECURITY.md`, and `CODE_OF_CONDUCT.md`; completed
  `_pkgdown.yml` with a grouped reference index; reconciled `.Rbuildignore` to
  the files that exist.

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
* `.external_facts` is now the canonical external-facts registry (`family`, `kind`,
  `value`, `source`, `verified_on`, `reverify_by`, `oracle_types`, `signoff`),
  validated per-family by `.validate_external_registry()` (gate F13/F14). Seven
  fact families are grounded by the recorded-real cassette; `fee_schedule` is
  reported as `[unverified]` (its auth-gated `/sapi` endpoint is
  unimplemented).
* `data-raw/record_fixtures.R` re-captures the cassettes against the live
  authority and prints the new hashes (the re-grounding script).
