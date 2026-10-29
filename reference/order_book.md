# A grounded order book

The object
[`bourse_orderbook()`](https://max578.github.io/bourse/reference/bourse_orderbook.md)
returns on success. It carries the `bids` and `asks` price/quantity
ladders (each a `data.frame` of `price`, `qty`), the `obs_schema`
describing each column's quantity and unit, and the `grounding` label
combined worst-case from the facts it rests on. `bids` are sorted best
(highest) first and `asks` best (lowest) first, the convention the
validator enforces.

## Usage

``` r
order_book(
  bids = NULL,
  asks = NULL,
  symbol = NA_character_,
  source = NA_character_,
  last_update_id = NA_real_,
  obs_schema = NULL,
  grounding = "[unverified]",
  metadata = list()
)
```

## Arguments

- bids:

  A `data.frame` of resting buy orders (`price`, `qty`).

- asks:

  A `data.frame` of resting sell orders (`price`, `qty`).

- symbol:

  The instrument symbol (e.g. `"BTCUSDT"`).

- source:

  The data source (e.g. `"binance"`).

- last_update_id:

  The exchange's order-book sequence id, when known.

- obs_schema:

  A `data.frame` of `(name, quantity, unit)` per column.

- grounding:

  A canonical grounding token.

- metadata:

  A named list of free-form metadata.

## Value

An `order_book` S7 object.

## See also

Other orderbook:
[`bourse_orderbook()`](https://max578.github.io/bourse/reference/bourse_orderbook.md)

## Examples

``` r
ob <- order_book(
  bids = data.frame(price = 100, qty = 1), asks = data.frame(price = 101, qty = 2),
  symbol = "X", source = "demo", grounding = grounding_unverified())
ob@symbol
#> [1] "X"
```
