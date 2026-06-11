# =============================================================================
# External-facts provenance registry (IOP obligation #1)
# =============================================================================
# Every fact bourse asserts about an exchange is recorded here, keyed by source
# and fact family, with the date it was last diffed against the authority. A
# fact with `verified_on = NA` is `[unverified]`: auditable, machine-visible, and
# never silently trusted. This is the artefact whose absence the nert incident
# proved decisive -- the gap is named, not hidden.

# The seed registry. Every fact starts un-grounded (`verified_on = NA`); the
# catalogue-diff oracle ([bourse_catalogue_diff()]) is the only thing that sets a
# real date. The fact families mirror the eight grounding obligations for a
# market connector.
.bourse_facts_seed <- function() {
  fam <- c("symbol_universe", "tick_size", "lot_size", "min_notional",
           "fee_schedule", "quote_base_currency", "timestamp_tz",
           "ohlcv_column_semantics")
  data.frame(
    source        = "binance",
    fact_family   = fam,
    asserted_value = c(
      "symbols from /api/v3/exchangeInfo",
      "PRICE_FILTER tickSize per symbol",
      "LOT_SIZE stepSize per symbol",
      "NOTIONAL (or legacy MIN_NOTIONAL) minNotional per symbol",
      "maker/taker from /sapi/v1/asset/tradeFee (auth) or docs default",
      "baseAsset/quoteAsset per symbol",
      "kline openTime/closeTime are ms since epoch, UTC",
      "kline cols: 1=openTime 2=open 3=high 4=low 5=close 6=volume(base)"),
    oracle_kind   = NA_character_,
    verified_on   = as.Date(NA),
    evidence_path = NA_character_,
    stringsAsFactors = FALSE
  )
}

# Package-internal mutable store, seeded at load.
.bourse_registry <- new.env(parent = emptyenv())

.registry_init <- function() {
  .bourse_registry$facts <- .bourse_facts_seed()
  invisible(NULL)
}

#' The external-facts provenance registry
#'
#' Returns bourse's provenance registry: one row per asserted fact, with the
#' date it was last diffed against the exchange authority (`verified_on`, `NA`
#' when un-grounded). This makes the grounding state of every fact auditable.
#'
#' @return A `data.frame` with columns `source`, `fact_family`,
#'   `asserted_value`, `oracle_kind`, `verified_on`, `evidence_path`.
#' @examples
#' bourse_external_facts()
#' @family grounding
#' @export
bourse_external_facts <- function() {
  if (is.null(.bourse_registry$facts)) {
    .registry_init()
  }
  .bourse_registry$facts
}

#' Grounding status of the external facts
#'
#' A compact summary of how many fact families are grounded versus
#' `[unverified]`, per source. A connector that reports all families
#' `[unverified]` is being honest about an un-run grounding check -- never a
#' fabricated date.
#'
#' @param source Optional source to filter on (e.g. `"binance"`).
#' @return A `data.frame` with `source`, `n_facts`, `n_grounded`,
#'   `n_unverified`.
#' @examples
#' bourse_fact_status()
#' @family grounding
#' @export
bourse_fact_status <- function(source = NULL) {
  facts <- bourse_external_facts()
  if (!is.null(source)) {
    facts <- facts[facts$source %in% source, , drop = FALSE]
  }
  grounded <- !is.na(facts$verified_on)
  agg <- by(
    data.frame(grounded = grounded),
    facts$source,
    function(d) c(n_facts = nrow(d), n_grounded = sum(d$grounded),
                  n_unverified = sum(!d$grounded))
  )
  out <- do.call(rbind, lapply(names(agg), function(s) {
    data.frame(source = s, t(agg[[s]]), row.names = NULL)
  }))
  out
}

# Internal: record that a fact family has been diffed against its authority.
# Only an oracle check (catalogue diff, recorded run) calls this -- never user
# code, and never with a fabricated date.
.ground_fact <- function(source, fact_family, on, oracle_kind, evidence_path) {
  facts <- bourse_external_facts()
  hit <- facts$source == source & facts$fact_family %in% fact_family
  facts$verified_on[hit]   <- on
  facts$oracle_kind[hit]   <- oracle_kind
  facts$evidence_path[hit] <- evidence_path
  .bourse_registry$facts <- facts
  invisible(facts)
}

#' Grounding token for a fact family
#'
#' Reads the registry and returns the canonical grounding token for one or more
#' fact families of a source: `grounding_grounded()` only if every requested
#' family has a non-`NA` `verified_on`.
#'
#' @param source The source (e.g. `"binance"`).
#' @param fact_family One or more fact-family names.
#' @return A canonical grounding token.
#' @examples
#' fact_grounding("binance", "tick_size")
#' @family grounding
#' @export
fact_grounding <- function(source, fact_family) {
  facts <- bourse_external_facts()
  hit <- facts$source == source & facts$fact_family %in% fact_family
  if (!any(hit)) {
    return(grounding_unverified())
  }
  if (all(!is.na(facts$verified_on[hit]))) {
    grounding_grounded()
  } else {
    grounding_unverified()
  }
}
