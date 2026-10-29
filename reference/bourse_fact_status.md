# Grounding status of the external facts

A compact summary of how many fact families are grounded versus
`[unverified]`, per source. A connector that reports all families
`[unverified]` states that the grounding check has not run – it never
reports a fabricated date.

## Usage

``` r
bourse_fact_status(source = NULL)
```

## Arguments

- source:

  Optional source to filter on (e.g. `"binance"`).

## Value

A `data.frame` with `source`, `n_facts`, `n_grounded`, `n_unverified`.

## See also

Other grounding:
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md),
[`bourse_external_facts()`](https://max578.github.io/bourse/reference/bourse_external_facts.md),
[`combine_grounding()`](https://max578.github.io/bourse/reference/combine_grounding.md),
[`fact_grounding()`](https://max578.github.io/bourse/reference/fact_grounding.md),
[`grounding_tokens`](https://max578.github.io/bourse/reference/grounding_tokens.md)

## Examples

``` r
bourse_fact_status()
#>    source n_facts n_grounded n_unverified
#> 1 binance      10          9            1
```
