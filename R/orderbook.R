# =============================================================================
# Order book — the depth verb
# =============================================================================
# Fetch (or parse) the top-of-book order book from `/api/v3/depth` and return it
# as a grounded `order_book`, or refuse. Like `bourse_ohlcv()`, the verb is
# splittable: pass `depth` to parse a recorded-real response offline (IOP
# obligation #4 -- a recorded authority response, never a self-authored golden),
# or omit it to fetch live (Suggests-gated).

#' A grounded order book
#'
#' The object [bourse_orderbook()] returns on success. It carries the `bids` and
#' `asks` price/quantity ladders (each a `data.frame` of `price`, `qty`), the
#' `obs_schema` describing each column's quantity and unit, and the `grounding`
#' label combined worst-case from the facts it rests on. `bids` are sorted best
#' (highest) first and `asks` best (lowest) first, the convention the validator
#' enforces.
#'
#' @param bids A `data.frame` of resting buy orders (`price`, `qty`).
#' @param asks A `data.frame` of resting sell orders (`price`, `qty`).
#' @param symbol The instrument symbol (e.g. `"BTCUSDT"`).
#' @param source The data source (e.g. `"binance"`).
#' @param last_update_id The exchange's order-book sequence id, when known.
#' @param obs_schema A `data.frame` of `(name, quantity, unit)` per column.
#' @param grounding A canonical grounding token.
#' @param metadata A named list of free-form metadata.
#' @return An `order_book` S7 object.
#' @examples
#' ob <- order_book(
#'   bids = data.frame(price = 100, qty = 1), asks = data.frame(price = 101, qty = 2),
#'   symbol = "X", source = "demo", grounding = grounding_unverified())
#' ob@symbol
#' @family orderbook
#' @export
order_book <- S7::new_class(
  "order_book",
  properties = list(
    bids           = S7::new_property(S7::class_any, default = NULL),
    asks           = S7::new_property(S7::class_any, default = NULL),
    symbol         = S7::new_property(S7::class_character,
                                      default = NA_character_),
    source         = S7::new_property(S7::class_character,
                                      default = NA_character_),
    last_update_id = S7::new_property(S7::class_numeric, default = NA_real_),
    obs_schema     = S7::new_property(S7::class_any, default = NULL),
    grounding      = S7::new_property(S7::class_character,
                                      default = "[unverified]"),
    metadata       = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@grounding) != 1L ||
          !self@grounding %in% c(grounding_grounded(), grounding_unverified())) {
      return("@grounding must be exactly one canonical grounding token")
    }
    ok_ladder <- function(d) {
      is.data.frame(d) && all(c("price", "qty") %in% names(d))
    }
    if (!is.null(self@bids) && !ok_ladder(self@bids)) {
      return("@bids must be a data.frame with `price` and `qty` columns")
    }
    if (!is.null(self@asks) && !ok_ladder(self@asks)) {
      return("@asks must be a data.frame with `price` and `qty` columns")
    }
    # A crossed book (best bid >= best ask) is a structural impossibility for a
    # resting book; refusing it here catches a transposed bid/ask ladder.
    bb <- if (is.data.frame(self@bids) && nrow(self@bids) > 0L) {
      self@bids$price[1L]
    } else NA_real_
    ba <- if (is.data.frame(self@asks) && nrow(self@asks) > 0L) {
      self@asks$price[1L]
    } else NA_real_
    if (!is.na(bb) && !is.na(ba) && bb >= ba) {
      return("crossed book: best bid must be below best ask")
    }
    NULL
  }
)

#' @export
S7::method(print, order_book) <- function(x, ...) {
  nb <- if (is.data.frame(x@bids)) nrow(x@bids) else 0L
  na <- if (is.data.frame(x@asks)) nrow(x@asks) else 0L
  cat(sprintf("<order_book> %s @ %s  %d bids / %d asks  [%s]\n",
              x@symbol, x@source, nb, na, x@grounding))
  invisible(x)
}

#' Fetch or parse an order book
#'
#' Returns a grounded [order_book] of the top-of-book bid/ask ladders for
#' `symbol`, or a [bourse_refusal] if it will not stand behind the result. The
#' book's grounding is `[unverified]` until [bourse_catalogue_diff()] has
#' grounded the relevant facts against the exchange catalogue.
#'
#' Supply `depth` (the parsed `/api/v3/depth` payload, a list with `bids` and
#' `asks`) to parse an offline recorded-real fixture; omit it to fetch live
#' (requires the suggested `httr2` and `jsonlite` packages).
#'
#' @param symbol The instrument symbol, e.g. `"BTCUSDT"`.
#' @param depth Optional recorded depth payload: a list with `bids` and `asks`,
#'   each a list of two-element `[price, qty]` arrays (the Binance shape). When
#'   supplied, no network call is made.
#' @param source The data source; currently `"binance"`.
#' @param quote_ccy,base_ccy Optional quote/base currency labels for the
#'   `obs_schema`; these are themselves facts and stay `[unverified]` until
#'   grounded.
#' @param limit Maximum levels to fetch live (each side).
#' @return An [order_book], or a [bourse_refusal].
#' @examples
#' # Offline: parse a small recorded-style depth payload.
#' payload <- list(
#'   lastUpdateId = 1,
#'   bids = list(c("100.0", "1.5"), c("99.9", "2.0")),
#'   asks = list(c("100.1", "1.0"), c("100.2", "3.0")))
#' bourse_orderbook("BTCUSDT", depth = payload)
#' @family orderbook
#' @export
bourse_orderbook <- function(symbol, depth = NULL, source = "binance",
                             quote_ccy = NULL, base_ccy = NULL, limit = 100L) {
  if (!source %in% .KNOWN_SOURCES) {
    return(.refuse("unknown_source",
                   sprintf("no adapter for source '%s'", source), source))
  }
  if (is.null(depth)) {
    if (!requireNamespace("httr2", quietly = TRUE) ||
          !requireNamespace("jsonlite", quietly = TRUE)) {
      return(.refuse("no_http_backend",
                     paste("live fetch needs the suggested 'httr2' +",
                           "'jsonlite'; pass `depth` to parse offline"),
                     source))
    }
    depth <- .binance_depth(symbol, limit)
    if (is_refusal(depth)) {
      return(depth)
    }
  }

  bids <- .parse_ladder(depth$bids)
  asks <- .parse_ladder(depth$asks)
  if (is.null(bids) || is.null(asks) ||
        nrow(bids) == 0L || nrow(asks) == 0L) {
    return(.refuse("malformed_depth",
                   "expected non-empty `bids` and `asks` price/qty ladders",
                   source))
  }
  if (anyNA(bids$price) || anyNA(asks$price)) {
    return(.refuse("malformed_depth",
                   "non-numeric price in the order-book ladder", source))
  }
  if (bids$price[1L] >= asks$price[1L]) {
    return(.refuse("crossed_book",
                   "best bid is not below best ask; refusing a crossed book",
                   source))
  }

  qc <- quote_ccy %||% NA_character_
  bc <- base_ccy %||% NA_character_
  # The book rests on the price/qty units (column semantics) and the symbol /
  # currency facts; its grounding is their worst case.
  g <- combine_grounding(c(
    fact_grounding(source, "orderbook_column_semantics"),
    fact_grounding(source, "symbol_universe"),
    fact_grounding(source, "quote_base_currency")
  ))
  lui <- depth$lastUpdateId %||% NA
  order_book(
    bids = bids, asks = asks, symbol = symbol, source = source,
    last_update_id = suppressWarnings(as.numeric(lui)),
    obs_schema = .orderbook_obs_schema(qc, bc, g), grounding = g,
    metadata = list(n_bids = nrow(bids), n_asks = nrow(asks),
                    fetched = if (is.null(depth)) "live" else "supplied")
  )
}

# Parse a Binance depth ladder (a list of two-element [price, qty] arrays) into
# a numeric data.frame. Returns NULL on a shape that is not a ladder.
.parse_ladder <- function(levels) {
  if (is.null(levels) || length(levels) == 0L) {
    return(data.frame(price = numeric(0L), qty = numeric(0L)))
  }
  # Each level is a length-2 array; a different shape is malformed.
  ok <- all(vapply(levels, function(lv) length(lv) >= 2L, logical(1L)))
  if (!ok) {
    return(NULL)
  }
  price <- suppressWarnings(as.numeric(vapply(levels, function(lv) {
    as.character(lv[[1L]])
  }, character(1L))))
  qty <- suppressWarnings(as.numeric(vapply(levels, function(lv) {
    as.character(lv[[2L]])
  }, character(1L))))
  data.frame(price = price, qty = qty)
}

# Low-level live depth fetch (Binance public REST). Suggests-gated; network.
.binance_depth <- function(symbol, limit) {
  url <- "https://api.binance.com/api/v3/depth"
  resp <- tryCatch(
    httr2::req_perform(
      httr2::req_url_query(httr2::request(url), symbol = symbol,
                           limit = limit)),
    error = function(e) e)
  if (inherits(resp, "error")) {
    return(.refuse("network_error", conditionMessage(resp), "binance"))
  }
  body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = FALSE),
                   error = function(e) e)
  if (inherits(body, "error") || is.null(body$bids) || is.null(body$asks)) {
    return(.refuse("bad_response", "depth response had no bids/asks ladders",
                   "binance"))
  }
  body
}
