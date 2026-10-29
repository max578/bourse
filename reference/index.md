# Package index

## Market-data verbs

The data verbs. Each returns a grounded result object or a refusal,
never a number it cannot stand behind.

- [`bourse_ohlcv()`](https://max578.github.io/bourse/reference/bourse_ohlcv.md)
  : Fetch or parse an OHLCV market series
- [`bourse_orderbook()`](https://max578.github.io/bourse/reference/bourse_orderbook.md)
  : Fetch or parse an order book
- [`bourse_ticker()`](https://max578.github.io/bourse/reference/bourse_ticker.md)
  : Fetch or parse a 24-hour ticker

## Result objects

The contract-typed S7 result objects and the refusal outcome.

- [`market_series()`](https://max578.github.io/bourse/reference/market_series.md)
  : A grounded market series
- [`order_book()`](https://max578.github.io/bourse/reference/order_book.md)
  : A grounded order book
- [`market_ticker()`](https://max578.github.io/bourse/reference/market_ticker.md)
  : A grounded 24-hour ticker
- [`bourse_refusal()`](https://max578.github.io/bourse/reference/bourse_refusal.md)
  : A refusal
- [`is_refusal()`](https://max578.github.io/bourse/reference/is_refusal.md)
  : Is this object a refusal?

## Grounding (the Independent Oracle Principle)

The provenance machinery: the catalogue-diff oracle, the external-facts
registry, and the canonical grounding vocabulary.

- [`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md)
  : Diff asserted facts against the exchange catalogue
- [`bourse_external_facts()`](https://max578.github.io/bourse/reference/bourse_external_facts.md)
  : The external-facts provenance registry
- [`bourse_fact_status()`](https://max578.github.io/bourse/reference/bourse_fact_status.md)
  : Grounding status of the external facts
- [`fact_grounding()`](https://max578.github.io/bourse/reference/fact_grounding.md)
  : Grounding token for a fact family
- [`grounding_grounded()`](https://max578.github.io/bourse/reference/grounding_tokens.md)
  [`grounding_unverified()`](https://max578.github.io/bourse/reference/grounding_tokens.md)
  : Canonical grounding tokens
- [`combine_grounding()`](https://max578.github.io/bourse/reference/combine_grounding.md)
  : Combine grounding worst-case

## Package

- [`bourse`](https://max578.github.io/bourse/reference/bourse-package.md)
  [`bourse-package`](https://max578.github.io/bourse/reference/bourse-package.md)
  : bourse: Grounded Market-Data Connector for the ORCHESTRA Framework
