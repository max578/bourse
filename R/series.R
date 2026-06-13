# =============================================================================
# Grounded market series + refusal
# =============================================================================
# `market_series` is bourse's result type: the OHLCV data, a per-column semantic
# descriptor (the obs_schema seam -- IOP obligation #3), and the grounding label
# carried beside the numbers. `bourse_refusal` is the other first-class outcome:
# bourse refuses rather than returning a silently wrong series when a required
# fact is missing or un-grounded (IOP obligation #7).

#' A grounded market series
#'
#' The object [bourse_ohlcv()] returns on success. It carries the OHLCV `data`,
#' the `obs_schema` describing each column's quantity and unit (so a consumer can
#' refuse to compare incommensurable columns), and the `grounding` label combined
#' worst-case from the facts the series rests on.
#'
#' @param data A `data.frame` of OHLCV rows.
#' @param symbol The instrument symbol (e.g. `"BTCUSDT"`).
#' @param source The data source (e.g. `"binance"`).
#' @param interval The candle interval (e.g. `"1d"`).
#' @param obs_schema A `data.frame` of `(name, quantity, unit)` per column.
#' @param grounding A canonical grounding token.
#' @param metadata A named list of free-form metadata.
#' @return A `market_series` S7 object.
#' @examples
#' s <- market_series(data = data.frame(close = 1), symbol = "X",
#'                    source = "demo", grounding = grounding_unverified())
#' s@symbol
#' @family series
#' @export
market_series <- S7::new_class(
  "market_series",
  properties = list(
    data       = S7::new_property(S7::class_any, default = NULL),
    symbol     = S7::new_property(S7::class_character, default = NA_character_),
    source     = S7::new_property(S7::class_character, default = NA_character_),
    interval   = S7::new_property(S7::class_character, default = NA_character_),
    obs_schema = S7::new_property(S7::class_any, default = NULL),
    grounding  = S7::new_property(S7::class_character, default = "[unverified]"),
    metadata   = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@grounding) != 1L ||
          !self@grounding %in% c(grounding_grounded(), grounding_unverified())) {
      return("@grounding must be exactly one canonical grounding token")
    }
    NULL
  }
)

#' @export
S7::method(print, market_series) <- function(x, ...) {
  n <- if (is.null(x@data)) 0L else nrow(x@data)
  cat(sprintf("<market_series> %s @ %s [%s]  %d rows  [%s]\n",
              x@symbol, x@source, x@interval, n, x@grounding))
  invisible(x)
}

#' A refusal
#'
#' The object bourse returns instead of a series when it will not assert a
#' number it cannot stand behind -- an unknown source, an un-grounded required
#' fact, a missing dependency. Refusal is a first-class outcome, not an error to
#' be caught and ignored.
#'
#' @param reason A short machine-readable reason code.
#' @param detail A human-readable explanation.
#' @param source The source the refusal concerns.
#' @return A `bourse_refusal` S7 object.
#' @examples
#' bourse_refusal(reason = "fact_ungrounded", detail = "tick size unverified")
#' @family series
#' @export
bourse_refusal <- S7::new_class(
  "bourse_refusal",
  properties = list(
    reason = S7::new_property(S7::class_character, default = NA_character_),
    detail = S7::new_property(S7::class_character, default = NA_character_),
    source = S7::new_property(S7::class_character, default = NA_character_)
  )
)

#' @export
S7::method(print, bourse_refusal) <- function(x, ...) {
  cat(sprintf("<bourse_refusal: %s> %s%s\n", x@reason, x@detail,
              if (!is.na(x@source)) sprintf(" (%s)", x@source) else ""))
  invisible(x)
}

#' Is this object a refusal?
#'
#' @param x Any object.
#' @return `TRUE` if `x` is a [bourse_refusal].
#' @examples
#' is_refusal(bourse_refusal(reason = "x"))
#' is_refusal(42)
#' @family series
#' @export
is_refusal <- function(x) {
  S7::S7_inherits(x, bourse_refusal)
}

# Internal refusal constructor.
.refuse <- function(reason, detail, source = NA_character_) {
  bourse_refusal(reason = reason, detail = detail, source = source)
}

# The grounded obs_schema for an OHLCV series. The column quantities/units are
# themselves facts about the exchange response, so the schema carries the
# grounding of the `ohlcv_column_semantics` family.
.ohlcv_obs_schema <- function(quote_ccy, base_ccy, grounding) {
  data.frame(
    name      = c("open_time", "open", "high", "low", "close", "volume"),
    quantity  = c("time", "price", "price", "price", "price", "volume"),
    unit      = c("ms_utc", quote_ccy, quote_ccy, quote_ccy, quote_ccy, base_ccy),
    grounding = grounding,
    stringsAsFactors = FALSE
  )
}

# The grounded obs_schema for an order book. Both ladders carry a `price`
# (in the quote currency) and a `qty` (in the base currency); the units are
# facts about the depth response, grounded by the `orderbook_column_semantics`
# family.
.orderbook_obs_schema <- function(quote_ccy, base_ccy, grounding) {
  data.frame(
    name      = c("price", "qty"),
    quantity  = c("price", "quantity"),
    unit      = c(quote_ccy, base_ccy),
    grounding = grounding,
    stringsAsFactors = FALSE
  )
}

# The grounded obs_schema for a 24-hour ticker. The unit of each field is a fact
# about the ticker response (prices in the quote currency, base volume in the
# base currency, quote volume in the quote currency, times in ms UTC), grounded
# by the `ticker_column_semantics` family.
.ticker_obs_schema <- function(fields, quote_ccy, base_ccy, grounding) {
  unit_for <- c(
    last_price = quote_ccy, open_price = quote_ccy, high_price = quote_ccy,
    low_price = quote_ccy, price_change = quote_ccy,
    price_change_percent = "percent", weighted_avg_price = quote_ccy,
    volume = base_ccy, quote_volume = quote_ccy, open_time = "ms_utc",
    close_time = "ms_utc")
  qty_for <- c(
    last_price = "price", open_price = "price", high_price = "price",
    low_price = "price", price_change = "price",
    price_change_percent = "ratio", weighted_avg_price = "price",
    volume = "volume", quote_volume = "volume", open_time = "time",
    close_time = "time")
  data.frame(
    name      = fields,
    quantity  = unname(qty_for[fields]),
    unit      = unname(unit_for[fields]),
    grounding = grounding,
    stringsAsFactors = FALSE
  )
}
