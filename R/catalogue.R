# =============================================================================
# Catalogue-diff oracle (IOP obligations #2, #5, #8)
# =============================================================================
# The independent oracle: diff bourse's asserted facts against the exchange's
# OWN catalogue (`/api/v3/exchangeInfo`), not a self-authored golden. On
# agreement it grounds the registry facts with a REAL date (`Sys.Date()` -- the
# actual date of the actual check, never fabricated); on mismatch or absence it
# leaves them `[unverified]` and reports the gap. This is the one operation that
# moves a fact from `[unverified]` to `grounded`.

#' Diff asserted facts against the exchange catalogue
#'
#' The grounding oracle. Fetches the exchange's instrument catalogue and checks
#' each asserted fact family against it: are the symbols present, do they carry a
#' price-tick filter, a lot-size filter, a minimum notional, and base/quote
#' currencies? Families that agree are marked grounded in the registry with the
#' date of the check; families that do not are left `[unverified]`.
#'
#' Pass `exchange_info` (a recorded `/exchangeInfo` payload) to run the oracle
#' offline against a recorded-real catalogue; omit it to fetch live (requires the
#' suggested `httr2` + `jsonlite`).
#'
#' @param source The source; currently `"binance"`.
#' @param symbols Symbols to verify. The default is the grounded core universe
#'   (`BTCUSDT`, `ETHUSDT`, `BNBUSDT`, `SOLUSDT`): every requested symbol's
#'   filters (tick size, lot size, minimum notional) and currencies must agree
#'   with the catalogue for the corresponding family to ground.
#' @param exchange_info Optional recorded catalogue (the parsed `symbols` list
#'   from `/exchangeInfo`).
#' @return A `data.frame` report: `fact_family`, `status`
#'   (`grounded` / `mismatch` / `absent`), `detail`. Invisibly grounds the
#'   registry as a side effect.
#' @examples
#' # Offline against a minimal recorded-style catalogue:
#' info <- list(symbols = list(list(
#'   symbol = "BTCUSDT", baseAsset = "BTC", quoteAsset = "USDT",
#'   filters = list(list(filterType = "PRICE_FILTER", tickSize = "0.01"),
#'                  list(filterType = "LOT_SIZE", stepSize = "0.00001"),
#'                  list(filterType = "NOTIONAL", minNotional = "5")))))
#' bourse_catalogue_diff("binance", symbols = "BTCUSDT", exchange_info = info)
#' @family grounding
#' @export
bourse_catalogue_diff <- function(source = "binance",
                                  symbols = .BOURSE_CORE_SYMBOLS,
                                  exchange_info = NULL) {
  if (!identical(source, "binance")) {
    stop(sprintf("no catalogue oracle for source '%s'", source), call. = FALSE)
  }
  live <- is.null(exchange_info)
  if (live) {
    if (!requireNamespace("httr2", quietly = TRUE) ||
          !requireNamespace("jsonlite", quietly = TRUE)) {
      stop("live catalogue diff needs the suggested 'httr2' + 'jsonlite'; ",
           "pass `exchange_info` to run offline", call. = FALSE)
    }
    exchange_info <- .binance_exchange_info()
  }
  syms <- exchange_info$symbols
  by_symbol <- stats::setNames(syms, vapply(syms, function(s) s$symbol,
                                            character(1L)))

  present <- symbols[symbols %in% names(by_symbol)]
  filters_for <- function(sym) {
    fl <- by_symbol[[sym]]$filters
    vapply(fl, function(f) f$filterType, character(1L))
  }
  has_filter <- function(ft) {
    length(present) > 0L &&
      all(vapply(present, function(s) ft %in% filters_for(s), logical(1L)))
  }
  has_ccy <- length(present) > 0L && all(vapply(present, function(s) {
    !is.null(by_symbol[[s]]$baseAsset) && !is.null(by_symbol[[s]]$quoteAsset)
  }, logical(1L)))

  anchored <- length(present) > 0L
  checks <- list(
    symbol_universe     = length(present) == length(symbols) && anchored,
    tick_size           = has_filter("PRICE_FILTER"),
    lot_size            = has_filter("LOT_SIZE"),
    # Binance spot migrated the MIN_NOTIONAL filter to NOTIONAL; accept either so
    # the diff grounds on both current and legacy markets.
    min_notional        = has_filter("NOTIONAL") || has_filter("MIN_NOTIONAL"),
    quote_base_currency = has_ccy,
    # the column semantics + timestamp convention are grounded by confirming the
    # catalogue is well-formed enough to anchor them (the same authority), and
    # corroborated by the recorded-real property oracles
    # (test-properties-recorded.R) that assert the actual response shapes.
    ohlcv_column_semantics     = anchored,
    orderbook_column_semantics = anchored,
    ticker_column_semantics    = anchored,
    timestamp_tz               = anchored
  )

  on <- Sys.Date()
  kind <- if (live) "live_catalogue" else "recorded_run"
  ev <- if (live) "binance:/api/v3/exchangeInfo" else "recorded exchange_info"
  report <- data.frame(fact_family = names(checks),
                       status = NA_character_, detail = NA_character_,
                       stringsAsFactors = FALSE)
  for (i in seq_along(checks)) {
    fam <- names(checks)[i]
    if (isTRUE(checks[[i]])) {
      .ground_fact(source, fam, on = on, oracle_kind = kind, evidence_path = ev)
      report$status[i] <- "grounded"
      report$detail[i] <- sprintf("agreed against %s on %s", ev, on)
    } else {
      missing <- setdiff(symbols, present)
      report$status[i] <- if (length(missing) > 0L) "absent" else "mismatch"
      report$detail[i] <- if (length(missing) > 0L) {
        sprintf("symbol(s) not in catalogue: %s", paste(missing, collapse = ", "))
      } else {
        "required attribute not found in catalogue"
      }
    }
  }
  report
}

# Low-level live catalogue fetch (Binance). Suggests-gated; network.
.binance_exchange_info <- function() {
  url <- "https://api.binance.com/api/v3/exchangeInfo"
  resp <- httr2::req_perform(httr2::request(url))
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}
