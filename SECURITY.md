# Security policy

## Scope

`bourse` reads **anonymous, public market-data endpoints** only (Binance public
REST: `/api/v3/exchangeInfo`, `/api/v3/klines`, `/api/v3/depth`,
`/api/v3/ticker/24hr`). It does **not** require, accept, store, or transmit API
keys, account credentials, or any private account data. The authenticated fee
endpoint (`/sapi/v1/asset/tradeFee`) is deliberately **not** implemented: it
would introduce a credential surface, and the `fee_schedule` fact is therefore
reported as `[unverified]` rather than fetched.

If you are wiring `bourse` into a system that *does* hold exchange credentials,
keep those credentials out of `bourse`'s call path entirely.

## Reporting a vulnerability

If you discover a security issue -- for example a path by which a credential
could leak through a `bourse` code path, or a way the grounding machinery could
be made to assert an ungrounded fact as grounded -- please report it privately to
the maintainer (see `DESCRIPTION`) rather than opening a public issue. Include a
minimal reproduction and the affected version.

You can expect an acknowledgement within a reasonable window and a coordinated
disclosure once a fix is available.

## Recorded fixtures

The committed test fixtures under `tests/testthat/fixtures/` are recorded-real
**public** market-data responses. They contain no credentials, no account data,
and no personal data, and each is hash-pinned in `fixtures/PROVENANCE.md`.
