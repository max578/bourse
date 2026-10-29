# A grounded 24-hour ticker

The object
[`bourse_ticker()`](https://max578.github.io/bourse/reference/bourse_ticker.md)
returns on success. It carries the 24-hour rolling-window statistics
(`last_price`, `open_price`, `high_price`, `low_price`, `price_change`,
`price_change_percent`, `weighted_avg_price`, `volume`, `quote_volume`,
`open_time`, `close_time`), the `obs_schema` describing each field's
quantity and unit, and the `grounding` label combined worst-case from
the facts it rests on.

## Usage

``` r
market_ticker(
  stats = list(),
  symbol = NA_character_,
  source = NA_character_,
  obs_schema = NULL,
  grounding = "[unverified]",
  metadata = list()
)
```

## Arguments

- stats:

  A named list of the 24-hour statistics (numeric where numeric).

- symbol:

  The instrument symbol (e.g. `"BTCUSDT"`).

- source:

  The data source (e.g. `"binance"`).

- obs_schema:

  A `data.frame` of `(name, quantity, unit)` per field.

- grounding:

  A canonical grounding token.

- metadata:

  A named list of free-form metadata.

## Value

A `market_ticker` S7 object.

## See also

Other ticker:
[`bourse_ticker()`](https://max578.github.io/bourse/reference/bourse_ticker.md)

## Examples

``` r
tk <- market_ticker(
  stats = list(last_price = 100, high_price = 110, low_price = 90),
  symbol = "X", source = "demo", grounding = grounding_unverified())
tk@symbol
#> [1] "X"
```
