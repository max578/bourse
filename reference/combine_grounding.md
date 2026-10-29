# Combine grounding worst-case

A series (or a decision) built from several facts is grounded only when
every fact is grounded; one un-grounded fact taints the whole. Tokens
are validated against the canonical vocabulary so a synonym is rejected
rather than silently mistaken for grounded.

## Usage

``` r
combine_grounding(tokens)
```

## Arguments

- tokens:

  A character vector of grounding tokens.

## Value

[`grounding_grounded()`](https://max578.github.io/bourse/reference/grounding_tokens.md)
if non-empty and all grounded, else
[`grounding_unverified()`](https://max578.github.io/bourse/reference/grounding_tokens.md).

## See also

Other grounding:
[`bourse_catalogue_diff()`](https://max578.github.io/bourse/reference/bourse_catalogue_diff.md),
[`bourse_external_facts()`](https://max578.github.io/bourse/reference/bourse_external_facts.md),
[`bourse_fact_status()`](https://max578.github.io/bourse/reference/bourse_fact_status.md),
[`fact_grounding()`](https://max578.github.io/bourse/reference/fact_grounding.md),
[`grounding_tokens`](https://max578.github.io/bourse/reference/grounding_tokens.md)

## Examples

``` r
combine_grounding(c(grounding_grounded(), grounding_unverified()))
#> [1] "[unverified]"
```
