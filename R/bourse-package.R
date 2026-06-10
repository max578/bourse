#' bourse: Grounded Market-Data Connector for the ORCHESTRA Framework
#'
#' Fetches historical and live market data (cryptocurrency OHLCV and related series) from public exchange APIs and emits it as a contract-typed, provenance-labelled series for the ORCHESTRA analytics framework. Every external fact -- a symbol, a price tick size, a fee schedule, a column unit -- is recorded in a provenance registry and treated as unverified until it has been diffed against the exchange own catalogue (the Independent Oracle Principle); an ungrounded fact triggers refusal rather than a silently wrong number.
#'
#' @keywords internal
"_PACKAGE"

# Register S7 methods with the base generics they extend, and seed the
# external-facts registry, at namespace load.
.onLoad <- function(libname, pkgname) {
  S7::methods_register()
  .registry_init()
}
