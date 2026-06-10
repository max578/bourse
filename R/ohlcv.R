# =============================================================================
# OHLCV — the core data verb
# =============================================================================
# Fetch (or parse) candlestick data and return it as a grounded `market_series`,
# or refuse. The verb is deliberately splittable: pass `candles` to parse a
# recorded-real response offline (IOP obligation #4 -- a recorded authority
# response, never a self-authored golden), or omit it to fetch live.

.KNOWN_SOURCES <- c("binance")

#' Fetch or parse an OHLCV market series
#'
#' Returns a grounded [market_series] of open/high/low/close/volume candles for
#' `symbol` at `interval`, or a [bourse_refusal] if it will not stand behind the
#' result. The series's grounding is `[unverified]` until [bourse_catalogue_diff()]
#' has diffed the relevant facts against the exchange catalogue -- so a consumer
#' on a live order path can gate on `is_refusal()` and the grounding label rather
#' than trust an unchecked number.
#'
#' Supply `candles` (a matrix or data.frame of recorded candles) to parse an
#' offline fixture; omit it to fetch live (requires the suggested `httr2` and
#' `jsonlite` packages).
#'
#' @param symbol The instrument symbol, e.g. `"BTCUSDT"`.
#' @param interval The candle interval, e.g. `"1d"`, `"1h"`.
#' @param candles Optional recorded candles (>= 6 columns: open time, open, high,
#'   low, close, volume). When supplied, no network call is made.
#' @param source The data source; currently `"binance"`.
#' @param quote_ccy,base_ccy Optional quote/base currency labels for the
#'   `obs_schema`; these are themselves facts and stay `[unverified]` until
#'   grounded.
#' @param limit Maximum candles to fetch live.
#' @return A [market_series], or a [bourse_refusal].
#' @examples
#' # Offline: parse a small recorded-style fixture (timestamps in ms UTC).
#' fixture <- cbind(
#'   open_time = c(1.5e12, 1.5e12 + 86400000),
#'   open = c(100, 102), high = c(105, 106), low = c(99, 101),
#'   close = c(102, 104), volume = c(1200, 1500))
#' bourse_ohlcv("BTCUSDT", interval = "1d", candles = fixture)
#' @family series
#' @export
bourse_ohlcv <- function(symbol, interval = "1d", candles = NULL,
                         source = "binance", quote_ccy = NULL, base_ccy = NULL,
                         limit = 500L) {
  if (!source %in% .KNOWN_SOURCES) {
    return(.refuse("unknown_source",
                   sprintf("no adapter for source '%s'", source), source))
  }
  if (is.null(candles)) {
    if (!requireNamespace("httr2", quietly = TRUE) ||
          !requireNamespace("jsonlite", quietly = TRUE)) {
      return(.refuse("no_http_backend",
                     "live fetch needs the suggested 'httr2' + 'jsonlite'; pass `candles` to parse offline",
                     source))
    }
    candles <- .binance_klines(symbol, interval, limit)
    if (is_refusal(candles)) {
      return(candles)
    }
  }

  m <- as.matrix(candles)
  if (ncol(m) < 6L || nrow(m) == 0L) {
    return(.refuse("malformed_candles",
                   "expected a non-empty matrix with >= 6 columns", source))
  }
  num <- function(j) suppressWarnings(as.numeric(m[, j]))
  df <- data.frame(
    open_time = num(1L), open = num(2L), high = num(3L),
    low = num(4L), close = num(5L), volume = num(6L)
  )
  if (anyNA(df$close)) {
    return(.refuse("malformed_candles",
                   "non-numeric price column in candles", source))
  }

  qc <- quote_ccy %||% NA_character_
  bc <- base_ccy %||% NA_character_
  # The series rests on three fact families; its grounding is their worst case.
  g <- combine_grounding(c(
    fact_grounding(source, "ohlcv_column_semantics"),
    fact_grounding(source, "timestamp_tz"),
    fact_grounding(source, "quote_base_currency")
  ))
  market_series(
    data = df, symbol = symbol, source = source, interval = interval,
    obs_schema = .ohlcv_obs_schema(qc, bc, g), grounding = g,
    metadata = list(n = nrow(df),
                    fetched = if (is.null(candles)) "live" else "supplied")
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Low-level live klines fetch (Binance public REST). Suggests-gated; network.
.binance_klines <- function(symbol, interval, limit) {
  url <- "https://api.binance.com/api/v3/klines"
  resp <- tryCatch(
    httr2::req_perform(
      httr2::req_url_query(httr2::request(url), symbol = symbol,
                           interval = interval, limit = limit)),
    error = function(e) e)
  if (inherits(resp, "error")) {
    return(.refuse("network_error", conditionMessage(resp), "binance"))
  }
  body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = TRUE),
                   error = function(e) e)
  if (inherits(body, "error") || !is.matrix(body) && !is.data.frame(body)) {
    return(.refuse("bad_response", "klines response was not a candle matrix",
                   "binance"))
  }
  body
}
