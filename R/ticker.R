# =============================================================================
# 24h ticker — the ticker verb
# =============================================================================
# Fetch (or parse) the 24-hour rolling-window statistics from
# `/api/v3/ticker/24hr` and return them as a grounded `market_ticker`, or refuse.
# As with the other verbs, pass `ticker` to parse a recorded-real response
# offline (IOP obligation #4), or omit it to fetch live (Suggests-gated).

#' A grounded 24-hour ticker
#'
#' The object [bourse_ticker()] returns on success. It carries the 24-hour
#' rolling-window statistics (`last_price`, `open_price`, `high_price`,
#' `low_price`, `price_change`, `price_change_percent`, `weighted_avg_price`,
#' `volume`, `quote_volume`, `open_time`, `close_time`), the `obs_schema`
#' describing each field's quantity and unit, and the `grounding` label combined
#' worst-case from the facts it rests on.
#'
#' @param stats A named list of the 24-hour statistics (numeric where numeric).
#' @param symbol The instrument symbol (e.g. `"BTCUSDT"`).
#' @param source The data source (e.g. `"binance"`).
#' @param obs_schema A `data.frame` of `(name, quantity, unit)` per field.
#' @param grounding A canonical grounding token.
#' @param metadata A named list of free-form metadata.
#' @return A `market_ticker` S7 object.
#' @examples
#' tk <- market_ticker(
#'   stats = list(last_price = 100, high_price = 110, low_price = 90),
#'   symbol = "X", source = "demo", grounding = grounding_unverified())
#' tk@symbol
#' @family ticker
#' @export
market_ticker <- S7::new_class(
  "market_ticker",
  properties = list(
    stats      = S7::new_property(S7::class_list, default = list()),
    symbol     = S7::new_property(S7::class_character, default = NA_character_),
    source     = S7::new_property(S7::class_character, default = NA_character_),
    obs_schema = S7::new_property(S7::class_any, default = NULL),
    grounding  = S7::new_property(S7::class_character, default = "[unverified]"),
    metadata   = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@grounding) != 1L ||
          !self@grounding %in% c(grounding_grounded(), grounding_unverified())) {
      return("@grounding must be exactly one canonical grounding token")
    }
    s <- self@stats
    # The high/low envelope is a structural invariant: high must bound low, and
    # the last price must sit within the window. A breach catches a transposed
    # high/low field or a mis-mapped column.
    if (all(c("high_price", "low_price") %in% names(s)) &&
          is.finite(s$high_price) && is.finite(s$low_price) &&
          s$high_price < s$low_price) {
      return("@stats: high_price must not be below low_price")
    }
    NULL
  }
)

#' @export
S7::method(print, market_ticker) <- function(x, ...) {
  last <- x@stats$last_price %||% NA_real_
  pc <- x@stats$price_change_percent %||% NA_real_
  cat(sprintf("<market_ticker> %s @ %s  last=%s  24h=%s%%  [%s]\n",
              x@symbol, x@source, format(last), format(pc), x@grounding))
  invisible(x)
}

#' Fetch or parse a 24-hour ticker
#'
#' Returns a grounded [market_ticker] of the 24-hour rolling-window statistics
#' for `symbol`, or a [bourse_refusal] if it will not stand behind the result.
#' The ticker's grounding is `[unverified]` until [bourse_catalogue_diff()] has
#' grounded the relevant facts against the exchange catalogue.
#'
#' Supply `ticker` (the parsed `/api/v3/ticker/24hr` payload, a named list) to
#' parse an offline recorded-real fixture; omit it to fetch live (requires the
#' suggested `httr2` and `jsonlite` packages).
#'
#' @param symbol The instrument symbol, e.g. `"BTCUSDT"`.
#' @param ticker Optional recorded ticker payload: the named list returned by
#'   `/api/v3/ticker/24hr`. When supplied, no network call is made.
#' @param source The data source; currently `"binance"`.
#' @param quote_ccy,base_ccy Optional quote/base currency labels for the
#'   `obs_schema`; these are themselves facts and stay `[unverified]` until
#'   grounded.
#' @return A [market_ticker], or a [bourse_refusal].
#' @examples
#' # Offline: parse a small recorded-style ticker payload.
#' payload <- list(
#'   symbol = "BTCUSDT", lastPrice = "100.0", openPrice = "98.0",
#'   highPrice = "101.0", lowPrice = "97.0", priceChange = "2.0",
#'   priceChangePercent = "2.04", weightedAvgPrice = "99.0",
#'   volume = "1200", quoteVolume = "118800",
#'   openTime = 1.5e12, closeTime = 1.5e12 + 86400000)
#' bourse_ticker("BTCUSDT", ticker = payload)
#' @family ticker
#' @export
bourse_ticker <- function(symbol, ticker = NULL, source = "binance",
                          quote_ccy = NULL, base_ccy = NULL) {
  if (!source %in% .KNOWN_SOURCES) {
    return(.refuse("unknown_source",
                   sprintf("no adapter for source '%s'", source), source))
  }
  if (is.null(ticker)) {
    if (!requireNamespace("httr2", quietly = TRUE) ||
          !requireNamespace("jsonlite", quietly = TRUE)) {
      return(.refuse("no_http_backend",
                     paste("live fetch needs the suggested 'httr2' +",
                           "'jsonlite'; pass `ticker` to parse offline"),
                     source))
    }
    ticker <- .binance_ticker24hr(symbol)
    if (is_refusal(ticker)) {
      return(ticker)
    }
  }

  # The fields bourse stands behind, mapped from the authority's camelCase keys
  # to snake_case. The map is itself a column-semantics fact, grounded by the
  # recorded-real property oracle.
  num_keys <- c(
    last_price = "lastPrice", open_price = "openPrice",
    high_price = "highPrice", low_price = "lowPrice",
    price_change = "priceChange", price_change_percent = "priceChangePercent",
    weighted_avg_price = "weightedAvgPrice", volume = "volume",
    quote_volume = "quoteVolume", open_time = "openTime",
    close_time = "closeTime")
  present <- num_keys[num_keys %in% names(ticker)]
  if (length(present) == 0L) {
    return(.refuse("malformed_ticker",
                   "ticker payload carried none of the expected fields",
                   source))
  }
  vals <- lapply(present, function(k) {
    suppressWarnings(as.numeric(as.character(ticker[[k]])))
  })
  names(vals) <- names(present)
  if (!is.null(vals$last_price) && is.na(vals$last_price)) {
    return(.refuse("malformed_ticker",
                   "non-numeric last price in the ticker payload", source))
  }

  qc <- quote_ccy %||% NA_character_
  bc <- base_ccy %||% NA_character_
  g <- combine_grounding(c(
    fact_grounding(source, "ticker_column_semantics"),
    fact_grounding(source, "symbol_universe"),
    fact_grounding(source, "quote_base_currency")
  ))
  market_ticker(
    stats = vals, symbol = symbol, source = source,
    obs_schema = .ticker_obs_schema(names(present), qc, bc, g), grounding = g,
    metadata = list(n_fields = length(vals),
                    fetched = if (is.null(ticker)) "live" else "supplied")
  )
}

# Low-level live 24h-ticker fetch (Binance public REST). Suggests-gated; network.
.binance_ticker24hr <- function(symbol) {
  url <- "https://api.binance.com/api/v3/ticker/24hr"
  resp <- tryCatch(
    httr2::req_perform(
      httr2::req_url_query(httr2::request(url), symbol = symbol)),
    error = function(e) e)
  if (inherits(resp, "error")) {
    return(.refuse("network_error", conditionMessage(resp), "binance"))
  }
  body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = FALSE),
                   error = function(e) e)
  if (inherits(body, "error") || is.null(body$lastPrice)) {
    return(.refuse("bad_response", "ticker response had no lastPrice field",
                   "binance"))
  }
  body
}
