# Fetch or parse an OHLCV market series

Returns a grounded
[market_series](https://max578.github.io/bourse/reference/market_series.md)
of open/high/low/close/volume candles for `symbol` at `interval`, or a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md)
if it will not stand behind the result. The series's grounding is
`[unverified]` until
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md)
has diffed the relevant facts against the exchange catalogue – so a
consumer on a live order path can gate on
[`is_refusal()`](https://max578.github.io/bourse/reference/is_refusal.md)
and the grounding label rather than trust an unchecked number.

## Usage

``` r
bourse_ohlcv(
  symbol,
  interval = "1d",
  candles = NULL,
  source = "binance",
  quote_ccy = NULL,
  base_ccy = NULL,
  limit = 500L
)
```

## Arguments

- symbol:

  The instrument symbol, e.g. `"BTCUSDT"`.

- interval:

  The candle interval, e.g. `"1d"`, `"1h"`.

- candles:

  Optional recorded candles (\>= 6 columns: open time, open, high, low,
  close, volume). When supplied, no network call is made.

- source:

  The data source; currently `"binance"`.

- quote_ccy, base_ccy:

  Optional quote/base currency labels for the `obs_schema`; these are
  themselves facts and stay `[unverified]` until grounded.

- limit:

  Maximum candles to fetch live.

## Value

A
[market_series](https://max578.github.io/bourse/reference/market_series.md),
or a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md).

## Details

Supply `candles` (a matrix or data.frame of recorded candles) to parse
an offline fixture; omit it to fetch live (requires the suggested
`httr2` and `jsonlite` packages).

## See also

Other series:
[`bourse_refusal()`](https://max578.github.io/bourse/reference/bourse_refusal.md),
[`is_refusal()`](https://max578.github.io/bourse/reference/is_refusal.md),
[`market_series()`](https://max578.github.io/bourse/reference/market_series.md)

## Examples

``` r
# Offline: parse a small recorded-style fixture (timestamps in ms UTC).
fixture <- cbind(
  open_time = c(1.5e12, 1.5e12 + 86400000),
  open = c(100, 102), high = c(105, 106), low = c(99, 101),
  close = c(102, 104), volume = c(1200, 1500))
bourse_ohlcv("BTCUSDT", interval = "1d", candles = fixture)
#> <market_series> BTCUSDT @ binance [1d]  2 rows  [grounded]
```
