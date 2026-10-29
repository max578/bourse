# API stability

`bourse` follows semantic versioning. During the `0.x` series the
package is **experimental**: the public API and the `market_series` /
`bourse_refusal` contracts may change between minor versions as the
connector is exercised by the ORCHESTRA trading arm. Breaking changes
are recorded at the top of `NEWS.md`.

## Stability ladder

- **Experimental (current, `0.x`).** Function signatures, the
  fact-family set, and the result objects may change. Pin a version for
  a reproducible pipeline.
- **Stable (from `1.0.0`).** The exported functions and the result
  contracts become subject to the deprecation policy below.

## Deprecation policy (from `1.0.0`)

A removed or renamed export passes through at least one minor version
emitting a deprecation warning that names its successor before it is
made defunct.
