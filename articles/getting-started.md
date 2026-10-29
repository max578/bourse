# Getting started with bourse

``` r

library(bourse)
```

## What bourse does

`bourse` is the market-data connector of the ORCHESTRA analytics
framework: it fetches cryptocurrency OHLCV candles from public exchange
APIs and returns them as a contract-typed, provenance-labelled series.
It is the trading-domain counterpart of the `terroir` geo-data
collector, and it is built around one discipline – the **Independent
Oracle Principle (IOP)**: a fact about an exchange (a symbol, a price
tick size, a fee, a column’s unit) is *unverified* until it has been
diffed against the exchange’s own catalogue. For a trading system that
is risk control, not bookkeeping: an unverified tick size or fee is a
silently wrong number that loses money.

## Two outcomes: a series, or a refusal

[`bourse_ohlcv()`](https://max578.github.io/bourse/reference/bourse_ohlcv.md)
returns either a grounded `market_series` or a `bourse_refusal`. It
refuses rather than returning a number it cannot stand behind. Here we
parse a recorded candle fixture offline (the live path uses the
suggested `httr2`).

``` r

fixture <- cbind(
  open_time = c(1.5e12, 1.5e12 + 86400000),
  open = c(100, 102), high = c(105, 106), low = c(99, 101),
  close = c(102, 104), volume = c(1200, 1500))

series <- bourse_ohlcv("BTCUSDT", interval = "1d", candles = fixture)
series
#> <market_series> BTCUSDT @ binance [1d]  2 rows  [[unverified]]
series@grounding
#> [1] "[unverified]"
```

The series is `[unverified]` – not because the candles are wrong, but
because nothing has yet confirmed that this symbol, its tick size, and
the column meaning match the exchange’s catalogue. A consumer on a live
order path gates on this.

An unknown source, or malformed candles, is refused:

``` r

bourse_ohlcv("BTCUSDT", candles = fixture, source = "nasdaq")
#> <bourse_refusal: unknown_source> no adapter for source 'nasdaq' (nasdaq)
```

## Order books and tickers

The same two-outcome, grounding-carrying contract covers the other
read-only endpoints.
[`bourse_orderbook()`](https://max578.github.io/bourse/reference/bourse_orderbook.md)
parses an order book (`/api/v3/depth`) and refuses a crossed book;
[`bourse_ticker()`](https://max578.github.io/bourse/reference/bourse_ticker.md)
parses the 24-hour statistics (`/api/v3/ticker/24hr`). Each carries an
`obs_schema` and a grounding label.

``` r

book <- bourse_orderbook("BTCUSDT", depth = list(
  bids = list(c("100.0", "1.5"), c("99.9", "2.0")),
  asks = list(c("100.1", "1.0"), c("100.2", "3.0"))))
book
#> <order_book> BTCUSDT @ binance  2 bids / 2 asks  [[unverified]]

ticker <- bourse_ticker("BTCUSDT", ticker = list(
  symbol = "BTCUSDT", lastPrice = "100.0", openPrice = "98.0",
  highPrice = "101.0", lowPrice = "97.0", volume = "1200",
  quoteVolume = "118800", openTime = 1.5e12, closeTime = 1.5e12 + 86400000))
ticker
#> <market_ticker> BTCUSDT @ binance  last=100  24h=NA%  [[unverified]]
```

A crossed book – best bid at or above best ask – is a structural
impossibility for a resting book, so it is refused rather than returned:

``` r

bourse_orderbook("BTCUSDT", depth = list(
  bids = list(c("101.0", "1.0")), asks = list(c("100.0", "1.0"))))
#> <bourse_refusal: crossed_book> best bid is not below best ask; refusing a crossed book (binance)
```

## The provenance registry

Every fact bourse asserts is in a registry, with the date it was last
checked. Until the oracle runs, every family is `[unverified]`:

``` r

bourse_fact_status("binance")
#>    source n_facts n_grounded n_unverified
#> 1 binance      10          0           10
```

The `fee_schedule` family is deliberately never grounded here: its
authority is the authenticated `/sapi/v1/asset/tradeFee` endpoint, which
would introduce an API-credential surface. `bourse` reads public,
anonymous endpoints only, so the fee schedule stays `[unverified]`
rather than substituting a documentation default it cannot diff against
the account’s actual fee tier.

## Grounding: the catalogue-diff oracle

[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md)
is the only operation that grounds a fact. It diffs the asserted facts
against the exchange’s own `/exchangeInfo` catalogue (here a recorded
catalogue shape; live by default). Families that agree are grounded with
a real date; the rest stay `[unverified]`.

``` r

info <- list(symbols = list(list(
  symbol = "BTCUSDT", baseAsset = "BTC", quoteAsset = "USDT",
  filters = list(
    list(filterType = "PRICE_FILTER", tickSize = "0.01"),
    list(filterType = "LOT_SIZE", stepSize = "0.00001"),
    list(filterType = "NOTIONAL", minNotional = "5")))))

bourse_catalogue_diff("binance", symbols = "BTCUSDT", exchange_info = info)
#>                  fact_family   status
#> 1            symbol_universe grounded
#> 2                  tick_size grounded
#> 3                   lot_size grounded
#> 4               min_notional grounded
#> 5        quote_base_currency grounded
#> 6     ohlcv_column_semantics grounded
#> 7 orderbook_column_semantics grounded
#> 8    ticker_column_semantics grounded
#> 9               timestamp_tz grounded
#>                                                detail
#> 1 agreed against recorded exchange_info on 2026-10-29
#> 2 agreed against recorded exchange_info on 2026-10-29
#> 3 agreed against recorded exchange_info on 2026-10-29
#> 4 agreed against recorded exchange_info on 2026-10-29
#> 5 agreed against recorded exchange_info on 2026-10-29
#> 6 agreed against recorded exchange_info on 2026-10-29
#> 7 agreed against recorded exchange_info on 2026-10-29
#> 8 agreed against recorded exchange_info on 2026-10-29
#> 9 agreed against recorded exchange_info on 2026-10-29
```

Now the same series is grounded, because the facts it rests on have been
verified against the authority:

``` r

bourse_ohlcv("BTCUSDT", candles = fixture)@grounding
#> [1] "grounded"
```

## Why this matters for the orchestra

`bourse` feeds the trading members (`kalmix`, `proxymix`) and the
`decideR` decision layer. Because the series carries its grounding
label, an un-grounded price feed propagates worst-case through the
pipeline and `decideR` forces a flat position – the capital firewall.
Reporting what is not grounded is the trading system’s risk control.
