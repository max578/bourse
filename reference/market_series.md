# A grounded market series

The object
[`bourse_ohlcv()`](https://max578.github.io/bourse/reference/bourse_ohlcv.md)
returns on success. It carries the OHLCV `data`, the `obs_schema`
describing each column's quantity and unit (so a consumer can refuse to
compare incommensurable columns), and the `grounding` label combined
worst-case from the facts the series rests on.

## Usage

``` r
market_series(
  data = NULL,
  symbol = NA_character_,
  source = NA_character_,
  interval = NA_character_,
  obs_schema = NULL,
  grounding = "[unverified]",
  metadata = list()
)
```

## Arguments

- data:

  A `data.frame` of OHLCV rows.

- symbol:

  The instrument symbol (e.g. `"BTCUSDT"`).

- source:

  The data source (e.g. `"binance"`).

- interval:

  The candle interval (e.g. `"1d"`).

- obs_schema:

  A `data.frame` of `(name, quantity, unit)` per column.

- grounding:

  A canonical grounding token.

- metadata:

  A named list of free-form metadata.

## Value

A `market_series` S7 object.

## See also

Other series:
[`bourse_ohlcv()`](https://max578.github.io/bourse/reference/bourse_ohlcv.md),
[`bourse_refusal()`](https://max578.github.io/bourse/reference/bourse_refusal.md),
[`is_refusal()`](https://max578.github.io/bourse/reference/is_refusal.md)

## Examples

``` r
s <- market_series(data = data.frame(close = 1), symbol = "X",
                   source = "demo", grounding = grounding_unverified())
s@symbol
#> [1] "X"
```
