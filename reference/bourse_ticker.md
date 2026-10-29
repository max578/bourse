# Fetch or parse a 24-hour ticker

Returns a grounded
[market_ticker](https://max578.github.io/bourse/reference/market_ticker.md)
of the 24-hour rolling-window statistics for `symbol`, or a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md)
if it will not stand behind the result. The ticker's grounding is
`[unverified]` until
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md)
has grounded the relevant facts against the exchange catalogue.

## Usage

``` r
bourse_ticker(
  symbol,
  ticker = NULL,
  source = "binance",
  quote_ccy = NULL,
  base_ccy = NULL
)
```

## Arguments

- symbol:

  The instrument symbol, e.g. `"BTCUSDT"`.

- ticker:

  Optional recorded ticker payload: the named list returned by
  `/api/v3/ticker/24hr`. When supplied, no network call is made.

- source:

  The data source; currently `"binance"`.

- quote_ccy, base_ccy:

  Optional quote/base currency labels for the `obs_schema`; these are
  themselves facts and stay `[unverified]` until grounded.

## Value

A
[market_ticker](https://max578.github.io/bourse/reference/market_ticker.md),
or a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md).

## Details

Supply `ticker` (the parsed `/api/v3/ticker/24hr` payload, a named list)
to parse an offline recorded-real fixture; omit it to fetch live
(requires the suggested `httr2` and `jsonlite` packages).

## See also

Other ticker:
[`market_ticker()`](https://max578.github.io/bourse/reference/market_ticker.md)

## Examples

``` r
# Offline: parse a small recorded-style ticker payload.
payload <- list(
  symbol = "BTCUSDT", lastPrice = "100.0", openPrice = "98.0",
  highPrice = "101.0", lowPrice = "97.0", priceChange = "2.0",
  priceChangePercent = "2.04", weightedAvgPrice = "99.0",
  volume = "1200", quoteVolume = "118800",
  openTime = 1.5e12, closeTime = 1.5e12 + 86400000)
bourse_ticker("BTCUSDT", ticker = payload)
#> <market_ticker> BTCUSDT @ binance  last=100  24h=2.04%  [grounded]
```
