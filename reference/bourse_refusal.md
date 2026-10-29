# A refusal

The object bourse returns instead of a series when it will not assert a
number it cannot stand behind – an unknown source, an un-grounded
required fact, a missing dependency. Refusal is a first-class outcome,
not an error to be caught and ignored.

## Usage

``` r
bourse_refusal(
  reason = NA_character_,
  detail = NA_character_,
  source = NA_character_
)
```

## Arguments

- reason:

  A short machine-readable reason code.

- detail:

  A human-readable explanation.

- source:

  The source the refusal concerns.

## Value

A `bourse_refusal` S7 object.

## See also

Other series:
[`bourse_ohlcv()`](https://max578.github.io/bourse/reference/bourse_ohlcv.md),
[`is_refusal()`](https://max578.github.io/bourse/reference/is_refusal.md),
[`market_series()`](https://max578.github.io/bourse/reference/market_series.md)

## Examples

``` r
bourse_refusal(reason = "fact_ungrounded", detail = "tick size unverified")
#> <bourse_refusal: fact_ungrounded> tick size unverified
```
