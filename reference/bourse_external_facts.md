# The external-facts provenance registry

Returns bourse's provenance registry: one row per asserted fact, with
the date it was last diffed against the exchange authority
(`verified_on`, `NA` when un-grounded). This makes the grounding state
of every fact auditable.

## Usage

``` r
bourse_external_facts()
```

## Value

A `data.frame` with columns `source`, `fact_family`, `asserted_value`,
`oracle_kind`, `verified_on`, `evidence_path`.

## See also

Other grounding:
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md),
[`bourse_fact_status()`](https://max578.github.io/bourse/reference/bourse_fact_status.md),
[`combine_grounding()`](https://max578.github.io/bourse/reference/combine_grounding.md),
[`fact_grounding()`](https://max578.github.io/bourse/reference/fact_grounding.md),
[`grounding_tokens`](https://max578.github.io/bourse/reference/grounding_tokens.md)

## Examples

``` r
bourse_external_facts()
#>     source                fact_family
#> 1  binance            symbol_universe
#> 2  binance                  tick_size
#> 3  binance                   lot_size
#> 4  binance               min_notional
#> 5  binance               fee_schedule
#> 6  binance        quote_base_currency
#> 7  binance               timestamp_tz
#> 8  binance     ohlcv_column_semantics
#> 9  binance orderbook_column_semantics
#> 10 binance    ticker_column_semantics
#>                                                            asserted_value
#> 1                                       symbols from /api/v3/exchangeInfo
#> 2                                        PRICE_FILTER tickSize per symbol
#> 3                                            LOT_SIZE stepSize per symbol
#> 4                NOTIONAL (or legacy MIN_NOTIONAL) minNotional per symbol
#> 5         maker/taker from /sapi/v1/asset/tradeFee (auth) or docs default
#> 6                                         baseAsset/quoteAsset per symbol
#> 7                        kline openTime/closeTime are ms since epoch, UTC
#> 8       kline cols: 1=openTime 2=open 3=high 4=low 5=close 6=volume(base)
#> 9       depth bids/asks are [price(quote), qty(base)] ladders, best-first
#> 10 ticker24hr lastPrice/openPrice/highPrice/lowPrice(quote), volume(base)
#>     oracle_kind verified_on          evidence_path
#> 1  recorded_run  2026-10-29 recorded exchange_info
#> 2  recorded_run  2026-10-29 recorded exchange_info
#> 3  recorded_run  2026-10-29 recorded exchange_info
#> 4  recorded_run  2026-10-29 recorded exchange_info
#> 5          <NA>        <NA>                   <NA>
#> 6  recorded_run  2026-10-29 recorded exchange_info
#> 7  recorded_run  2026-10-29 recorded exchange_info
#> 8  recorded_run  2026-10-29 recorded exchange_info
#> 9  recorded_run  2026-10-29 recorded exchange_info
#> 10 recorded_run  2026-10-29 recorded exchange_info
```
