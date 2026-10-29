# Fetch or parse an order book

Returns a grounded
[order_book](https://max578.github.io/bourse/reference/order_book.md) of
the top-of-book bid/ask ladders for `symbol`, or a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md)
if it will not stand behind the result. The book's grounding is
`[unverified]` until
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md)
has grounded the relevant facts against the exchange catalogue.

## Usage

``` r
bourse_orderbook(
  symbol,
  depth = NULL,
  source = "binance",
  quote_ccy = NULL,
  base_ccy = NULL,
  limit = 100L
)
```

## Arguments

- symbol:

  The instrument symbol, e.g. `"BTCUSDT"`.

- depth:

  Optional recorded depth payload: a list with `bids` and `asks`, each a
  list of two-element `[price, qty]` arrays (the Binance shape). When
  supplied, no network call is made.

- source:

  The data source; currently `"binance"`.

- quote_ccy, base_ccy:

  Optional quote/base currency labels for the `obs_schema`; these are
  themselves facts and stay `[unverified]` until grounded.

- limit:

  Maximum levels to fetch live (each side).

## Value

An
[order_book](https://max578.github.io/bourse/reference/order_book.md),
or a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md).

## Details

Supply `depth` (the parsed `/api/v3/depth` payload, a list with `bids`
and `asks`) to parse an offline recorded-real fixture; omit it to fetch
live (requires the suggested `httr2` and `jsonlite` packages).

## See also

Other orderbook:
[`order_book()`](https://max578.github.io/bourse/reference/order_book.md)

## Examples

``` r
# Offline: parse a small recorded-style depth payload.
payload <- list(
  lastUpdateId = 1,
  bids = list(c("100.0", "1.5"), c("99.9", "2.0")),
  asks = list(c("100.1", "1.0"), c("100.2", "3.0")))
bourse_orderbook("BTCUSDT", depth = payload)
#> <order_book> BTCUSDT @ binance  2 bids / 2 asks  [grounded]
```
