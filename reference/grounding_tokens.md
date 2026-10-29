# Canonical grounding tokens

The two states a market fact can occupy under the Independent Oracle
Principle. `grounding_grounded()` is the token for a fact diffed against
the exchange catalogue that owns it; `grounding_unverified()` is the
default for everything else. The brackets in `"[unverified]"` are
load-bearing: they make an un-grounded label unmissable wherever it
surfaces.

## Usage

``` r
grounding_grounded()

grounding_unverified()
```

## Value

A length-one character string holding the canonical token.

## See also

Other grounding:
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md),
[`bourse_external_facts()`](https://max578.github.io/bourse/reference/bourse_external_facts.md),
[`bourse_fact_status()`](https://max578.github.io/bourse/reference/bourse_fact_status.md),
[`combine_grounding()`](https://max578.github.io/bourse/reference/combine_grounding.md),
[`fact_grounding()`](https://max578.github.io/bourse/reference/fact_grounding.md)

## Examples

``` r
grounding_grounded()
#> [1] "grounded"
grounding_unverified()
#> [1] "[unverified]"
```
