# bourse: Grounded Market-Data Connector for the ORCHESTRA Framework

Fetches historical and live market data (cryptocurrency OHLCV and
related series) from public exchange APIs and emits it as a
contract-typed, provenance-labelled series for the ORCHESTRA analytics
framework. Every external fact – a symbol, a price tick size, a fee
schedule, a column unit – is recorded in a provenance registry and
treated as unverified until it has been diffed against the exchange's
own catalogue (the Independent Oracle Principle); an ungrounded fact
triggers refusal rather than a silently wrong number.

## See also

Useful links:

- <https://github.com/max578/bourse>

- <https://max578.github.io/bourse/>

- Report bugs at <https://github.com/max578/bourse/issues>

## Author

**Maintainer**: Max Moldovan <max.moldovan@adelaide.edu.au>
([ORCID](https://orcid.org/0000-0001-9680-8474))

Authors:

- Max Moldovan <max.moldovan@adelaide.edu.au>
  ([ORCID](https://orcid.org/0000-0001-9680-8474))
