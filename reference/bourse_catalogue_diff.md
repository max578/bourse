# Diff asserted facts against the exchange catalogue

The grounding oracle. Fetches the exchange's instrument catalogue and
checks each asserted fact family against it: are the symbols present, do
they carry a price-tick filter, a lot-size filter, a minimum notional,
and base/quote currencies? Families that agree are marked grounded in
the registry with the date of the check; families that do not are left
`[unverified]`.

## Usage

``` r
bourse_catalogue_diff(
  source = "binance",
  symbols = .BOURSE_CORE_SYMBOLS,
  exchange_info = NULL
)
```

## Arguments

- source:

  The source; currently `"binance"`.

- symbols:

  Symbols to verify. The default is the grounded core universe
  (`BTCUSDT`, `ETHUSDT`, `BNBUSDT`, `SOLUSDT`): every requested symbol's
  filters (tick size, lot size, minimum notional) and currencies must
  agree with the catalogue for the corresponding family to ground.

- exchange_info:

  Optional recorded catalogue (the parsed `symbols` list from
  `/exchangeInfo`).

## Value

A `data.frame` report: `fact_family`, `status` (`grounded` / `mismatch`
/ `absent`), `detail`. Invisibly grounds the registry as a side effect.

## Details

Pass `exchange_info` (a recorded `/exchangeInfo` payload) to run the
oracle offline against a recorded-real catalogue; omit it to fetch live
(requires the suggested `httr2` + `jsonlite`).

## See also

Other grounding:
[`bourse_external_facts()`](https://max578.github.io/bourse/reference/bourse_external_facts.md),
[`bourse_fact_status()`](https://max578.github.io/bourse/reference/bourse_fact_status.md),
[`combine_grounding()`](https://max578.github.io/bourse/reference/combine_grounding.md),
[`fact_grounding()`](https://max578.github.io/bourse/reference/fact_grounding.md),
[`grounding_tokens`](https://max578.github.io/bourse/reference/grounding_tokens.md)

## Examples

``` r
# Offline against a minimal recorded-style catalogue:
info <- list(symbols = list(list(
  symbol = "BTCUSDT", baseAsset = "BTC", quoteAsset = "USDT",
  filters = list(list(filterType = "PRICE_FILTER", tickSize = "0.01"),
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
