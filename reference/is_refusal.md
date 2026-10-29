# Is this object a refusal?

Is this object a refusal?

## Usage

``` r
is_refusal(x)
```

## Arguments

- x:

  Any object.

## Value

`TRUE` if `x` is a
[bourse_refusal](https://max578.github.io/bourse/reference/bourse_refusal.md).

## See also

Other series:
[`bourse_ohlcv()`](https://max578.github.io/bourse/reference/bourse_ohlcv.md),
[`bourse_refusal()`](https://max578.github.io/bourse/reference/bourse_refusal.md),
[`market_series()`](https://max578.github.io/bourse/reference/market_series.md)

## Examples

``` r
is_refusal(bourse_refusal(reason = "x"))
#> [1] TRUE
is_refusal(42)
#> [1] FALSE
```
