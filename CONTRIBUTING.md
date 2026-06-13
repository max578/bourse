# Contributing to bourse

Thank you for your interest in `bourse`, the grounded market-data connector of
the ORCHESTRA analytics framework. This document describes how to propose a
change.

## The grounding discipline (read this first)

`bourse` exists to enforce one principle: **the Independent Oracle Principle
(IOP)**. Every fact about an exchange -- a symbol, a price tick size, a fee, a
column's unit -- is `[unverified]` until it has been diffed against the
exchange's own catalogue or a recorded-real response. A contribution that asserts
a new external fact (a new endpoint's columns, a new symbol's filters, a new
exchange's conventions) must:

1. Add the fact to the provenance registry (`R/external_facts.R`) with the
   honest default `verified_on = NA`.
2. Ground it against the authority with a **recorded-real cassette** -- a payload
   captured from the live API by `data-raw/record_fixtures.R`, never a
   hand-authored literal. A hand-authored fixture is the circular mock that hides
   drift; this is a hard rule.
3. Pin the cassette's `sha256` + `md5` in `tests/testthat/fixtures/PROVENANCE.md`
   and assert the `md5` in a test (the meta-oracle), plus a property / structural
   oracle on the captured payload.

If a fact cannot be grounded, leave it `[unverified]` and have the verb refuse,
rather than returning a number the package cannot stand behind. Honest abstention
beats a silently wrong number.

## Development workflow

- Iterate with `devtools::load_all()`; never `R CMD INSTALL` while the package is
  loaded.
- `devtools::document()` after any roxygen change; `devtools::test()` before a
  push; `R CMD check --as-cran` before a release.
- Vignettes are `.Rmd` (the `R CMD check --as-cran` first-class engine).
- The package targets a zero-warning `--as-cran` check.

## Code style

Base R plus `data.table`; `snake_case`; `<-` for assignment; `TRUE` / `FALSE`
spelled out; two-space indentation; lines within roughly 80 characters;
`pkg::fun()` qualification for non-base namespaces; `seq_len()` / `vapply()` over
unguarded `1:n` / `sapply()`. No tidyverse idioms.

## Reporting a bug

Open an issue describing the call, the observed output (including any
`bourse_refusal`), and the expected output. If it concerns a grounding mismatch
against the live exchange, include the date and the relevant `/exchangeInfo` (or
endpoint) excerpt -- that is exactly the kind of drift `bourse` is built to catch.

## Conduct

By participating you agree to abide by the project's Code of Conduct
(`CODE_OF_CONDUCT.md`).
