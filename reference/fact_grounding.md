# Grounding token for a fact family

Reads the registry and returns the canonical grounding token for one or
more fact families of a source:
[`grounding_grounded()`](https://max578.github.io/bourse/reference/grounding_tokens.md)
only if every requested family has a non-`NA` `verified_on`.

## Usage

``` r
fact_grounding(source, fact_family)
```

## Arguments

- source:

  The source (e.g. `"binance"`).

- fact_family:

  One or more fact-family names.

## Value

A canonical grounding token.

## See also

Other grounding:
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md),
[`bourse_external_facts()`](https://max578.github.io/bourse/reference/bourse_external_facts.md),
[`bourse_fact_status()`](https://max578.github.io/bourse/reference/bourse_fact_status.md),
[`combine_grounding()`](https://max578.github.io/bourse/reference/combine_grounding.md),
[`grounding_tokens`](https://max578.github.io/bourse/reference/grounding_tokens.md)

## Examples

``` r
fact_grounding("binance", "tick_size")
#> [1] "grounded"
```
