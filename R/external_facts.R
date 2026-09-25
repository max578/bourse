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
           "ohlcv_column_semantics", "orderbook_column_semantics",
           "ticker_column_semantics")
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
      "kline cols: 1=openTime 2=open 3=high 4=low 5=close 6=volume(base)",
      "depth bids/asks are [price(quote), qty(base)] ladders, best-first",
      "ticker24hr lastPrice/openPrice/highPrice/lowPrice(quote), volume(base)"),
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

# =============================================================================
# Canonical recipe-52 registry (the /rpkg audit's F13/F14 contract surface)
# =============================================================================
# Derived from `.bourse_facts_seed()` so there is ONE source of truth for the
# family list + asserted values (a drift-guard test asserts the two agree). The
# seed is the *runtime* view (every family starts `[unverified]`, grounded live
# by `bourse_catalogue_diff()`); `.external_facts` below is the *static*
# provenance registry whose `verified_on` is set by the committed recorded-real
# cassette evidence: the oracle tests replay the recorded-real fixtures under
# `tests/testthat/fixtures/binance_*.json` (recorded-real `/exchangeInfo` --
# single + multi-symbol -- `/klines`, `/depth`, and `/ticker/24hr` captured
# 2026-09-25, hash-pinned in `fixtures/PROVENANCE.md`) and diff the asserted
# facts against them on every run. No `verified_on` is ever fabricated --
# `fee_schedule` is genuinely un-grounded (its `/sapi/v1/asset/tradeFee` endpoint
# is auth-gated and unimplemented) and stays `verified_on = NA`, honestly
# `[unverified]`.
#
# `kind`/`oracle_types` encode the recipe-52 taxonomy. The schema/enum/units
# families are *silent* (a wrong filter field or a mis-mapped kline column
# returns wrong output with NO error), so they carry a D/E/F oracle: D = physical
# / structural property invariants asserted on the recorded-real extract
# (`test-properties-recorded.R`); E = differential of the asserted fact vs the
# recorded-real authority response (`test-catalogue-diff.R`). B = catalogue diff
# against the live / recorded `/exchangeInfo`; A = live resolution of the
# endpoint (gated). All base R, so the audit can source this file in a vanilla
# session.

.BOURSE_SOURCE <- paste0(
  "Binance public REST API (api.binance.com): /api/v3/exchangeInfo + ",
  "/api/v3/klines + /api/v3/depth + /api/v3/ticker/24hr; oracle = recorded-real ",
  "cassette replay + live catalogue diff")

# Capture date of the committed recorded-real fixtures (fixtures/PROVENANCE.md).
.BOURSE_CASSETTE_ON <- "2026-09-25"

# The grounded core symbol universe -- the symbols whose filters are diffed
# against the live / recorded `/exchangeInfo` and so carry a real `verified_on`.
# This is the single source of truth for the multi-symbol grounded set
# (`bourse_catalogue_diff()` default + the multi-symbol oracle test + the
# multi-symbol cassette recorded by `data-raw/record_fixtures.R`).
.BOURSE_CORE_SYMBOLS <- c("BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT")

.BOURSE_FACT_KIND <- c(
  symbol_universe            = "enum",
  tick_size                  = "schema",
  lot_size                   = "schema",
  min_notional               = "schema",
  fee_schedule               = "constant",
  quote_base_currency        = "schema",
  timestamp_tz               = "units",
  ohlcv_column_semantics     = "schema",
  orderbook_column_semantics = "schema",
  ticker_column_semantics    = "schema")

.BOURSE_FACT_ORACLE <- c(
  symbol_universe            = "A,B,E",
  tick_size                  = "B,D,E",
  lot_size                   = "B,D,E",
  min_notional               = "B,D,E",
  fee_schedule               = "A",      # un-grounded: locator only, no D/E/F
  quote_base_currency        = "B,E",
  timestamp_tz               = "D,E",
  ohlcv_column_semantics     = "D,E",
  orderbook_column_semantics = "D,E",
  ticker_column_semantics    = "D,E")

# Families the committed recorded-real cassette + oracle tests actually ground.
# `fee_schedule` is FALSE on purpose -- not grounded, not pretended.
.BOURSE_FACT_GROUNDED <- c(
  symbol_universe            = TRUE,
  tick_size                  = TRUE,
  lot_size                   = TRUE,
  min_notional               = TRUE,
  fee_schedule               = FALSE,
  quote_base_currency        = TRUE,
  timestamp_tz               = TRUE,
  ohlcv_column_semantics     = TRUE,
  orderbook_column_semantics = TRUE,
  ticker_column_semantics    = TRUE)

.external_facts <- local({
  seed <- .bourse_facts_seed()
  fams <- seed$fact_family
  data.frame(
    family       = fams,
    fact_id      = paste0("binance.", fams),
    kind         = unname(.BOURSE_FACT_KIND[fams]),
    value        = seed$asserted_value,
    source       = .BOURSE_SOURCE,
    verified_on  = ifelse(.BOURSE_FACT_GROUNDED[fams],
                          .BOURSE_CASSETTE_ON, NA_character_),
    reverify_by  = "volatile",     # a live exchange API surface (90-day window)
    oracle_types = unname(.BOURSE_FACT_ORACLE[fams]),
    signoff      = NA_character_,
    stringsAsFactors = FALSE)
})

# Silent-failure kinds: a wrong value returns wrong output with NO error, so a
# live call "succeeding" is not enough -- they need a property / differential /
# human oracle (D/E/F). (recipe 52 section 2)
.silent_fact_kinds <- c("enum", "crs", "units", "constant", "schema", "rule")

# NA-safe ISO date parse (never errors on bad input).
.parse_iso <- function(x) as.Date(as.character(x), format = "%Y-%m-%d")

#' Validate the external-fact registry (gate F13/F14 contract)
#'
#' Pure-R, no network. Run by bourse's own tests and invoked by the `/rpkg`
#' audit driver. Returns one row per family with `pass` (logical) and, on
#' failure, a `reason`. Per-family: a family passes when every one of its rows
#' has a non-empty `source` + a parseable, in-window `verified_on`, a non-empty
#' `oracle_types` that includes a D/E/F oracle for silent kinds (and a `signoff`
#' for `rule` kinds), AND the family is referenced by an independent-oracle test
#' file. An un-grounded family (`verified_on = NA`, e.g. `fee_schedule`) honestly
#' fails -- it is `[unverified]` by design, surfaced, never papered over.
#'
#' @param registry The registry `data.frame` (default `.external_facts`).
#' @param test_dir Path to `tests/testthat` for the oracle-coverage check.
#' @returns A `data.frame`: `family`, `pass` (logical), `reason`.
#' @noRd
#' @keywords internal
.validate_external_registry <- function(registry = .external_facts,
                                        test_dir = "tests/testthat") {
  oracle_files <- list.files(
    test_dir,
    pattern = "test-(contract-live|catalogue-diff|properties-recorded)\\.R$",
    full.names = TRUE)
  oracle_blob <- if (length(oracle_files)) paste(
    vapply(oracle_files, function(f) paste(readLines(f, warn = FALSE),
                                           collapse = "\n"), character(1L)),
    collapse = "\n") else ""

  window <- c(volatile = 90L, stable = 365L, literature = .Machine$integer.max)

  per_family <- function(f) {
    sub <- registry[registry$family == f, , drop = FALSE]
    reasons <- character()
    if (any(!nzchar(sub$source) | is.na(sub$source)))
      reasons <- c(reasons, "empty `source`")
    vd <- .parse_iso(sub$verified_on)
    if (any(is.na(vd))) {
      reasons <- c(reasons, "[unverified]: no grounding date")
    } else {
      days <- vapply(sub$reverify_by, function(p)
        if (p %in% names(window)) window[[p]] else NA_integer_, integer(1L))
      if (any(!is.na(days) & as.integer(Sys.Date() - vd) > days))
        reasons <- c(reasons, "past re-grounding window")
    }
    if (any(!nzchar(sub$oracle_types) | is.na(sub$oracle_types)))
      reasons <- c(reasons, "empty `oracle_types`")
    if (any(sub$kind %in% .silent_fact_kinds &
              !grepl("[DEF]", sub$oracle_types)))
      reasons <- c(reasons,
                   "silent kind without a D/E/F oracle (recipe 52 section 2)")
    if (any(sub$kind == "rule" &
              (is.na(sub$signoff) | !nzchar(sub$signoff))))
      reasons <- c(reasons, "`rule` kind without a `signoff`")
    covered <- grepl(f, oracle_blob, fixed = TRUE) ||
      any(grepl(sub$fact_id, oracle_blob, fixed = TRUE))
    if (!covered)
      reasons <- c(reasons,
                   "no independent-oracle test references this family (F14)")
    list(pass = length(reasons) == 0L,
         reason = if (length(reasons)) paste(reasons, collapse = "; ")
                  else NA_character_)
  }

  fams <- registry$family
  res <- lapply(fams, per_family)
  data.frame(
    family = fams,
    pass   = vapply(res, `[[`, logical(1L), "pass"),
    reason = vapply(res, `[[`, character(1L), "reason"),
    stringsAsFactors = FALSE)
}
