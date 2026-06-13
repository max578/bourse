# The catalogue-diff oracle is the only thing that moves a fact from
# [unverified] to grounded. The offline tests replay a RECORDED-REAL Binance
# /exchangeInfo response captured from the live authority
# (fixtures/binance_exchangeInfo_*.json, hash-pinned in fixtures/PROVENANCE.md)
# -- NOT a hand-authored golden of bourse's own making, which is the circular
# mock that let the legacy `MIN_NOTIONAL` name ride green until the round-3
# grounding audit caught it against the live authority. A separate network test
# grounds against the live authority (skipped on CRAN / offline).

.recorded_exchange_info <- function() {
  skip_if_not_installed("jsonlite")
  path <- testthat::test_path("fixtures", "binance_exchangeInfo_BTCUSDT.json")
  # Meta-oracle (recipe 52 section 8): a silent re-record changes the hash and
  # fails here, so a fixture can never quietly drift away from the real
  # authority.
  if (!identical(unname(tools::md5sum(path)),
                 "e6f23b4bd5f3d1a652fe21d6b35cc1b7")) {
    stop("recorded cassette hash drift: re-run data-raw/record_fixtures.R and ",
         "update PROVENANCE.md + the asserted hashes.", call. = FALSE)
  }
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# The multi-symbol catalogue: one recorded-real /exchangeInfo capture carrying
# all four grounded core symbols, hash-guarded the same way.
.recorded_exchange_info_multi <- function() {
  skip_if_not_installed("jsonlite")
  path <- testthat::test_path("fixtures", "binance_exchangeInfo_multi.json")
  if (!identical(unname(tools::md5sum(path)),
                 "da9eb072c62a39a7fcfa69078b606571")) {
    stop("recorded multi-symbol cassette hash drift: re-run ",
         "data-raw/record_fixtures.R and update PROVENANCE.md + the hashes.",
         call. = FALSE)
  }
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

test_that("the oracle grounds families that agree with the catalogue", {
  .registry_init()
  rep <- bourse_catalogue_diff("binance", symbols = "BTCUSDT",
                               exchange_info = .recorded_exchange_info())
  expect_true(all(rep$status[rep$fact_family %in%
                               c("symbol_universe", "tick_size", "lot_size",
                                 "min_notional", "quote_base_currency")] ==
                    "grounded"))
  # the registry now reflects a REAL verified_on date for those families
  expect_identical(fact_grounding("binance", "tick_size"), grounding_grounded())
  st <- bourse_fact_status("binance")
  expect_true(st$n_grounded >= 5L)
})

test_that("the oracle grounds the full multi-symbol core universe", {
  # symbol_universe grounds only when EVERY requested symbol is present and each
  # carries the PRICE_FILTER / LOT_SIZE / NOTIONAL filters + base/quote assets.
  # This is the multi-symbol coverage: one cassette grounds four symbols.
  .registry_init()
  rep <- bourse_catalogue_diff("binance", symbols = .BOURSE_CORE_SYMBOLS,
                               exchange_info = .recorded_exchange_info_multi())
  grounded_fams <- c("symbol_universe", "tick_size", "lot_size",
                     "min_notional", "quote_base_currency")
  expect_true(all(rep$status[rep$fact_family %in% grounded_fams] == "grounded"))
  expect_identical(fact_grounding("binance", "tick_size"), grounding_grounded())
})

test_that("a partial multi-symbol set is reported absent, not grounded", {
  # If even one requested symbol is missing from the catalogue, symbol_universe
  # must NOT ground -- a connector cannot stand behind a symbol it did not see.
  .registry_init()
  rep <- bourse_catalogue_diff(
    "binance", symbols = c(.BOURSE_CORE_SYMBOLS, "NOTAREALSYM"),
    exchange_info = .recorded_exchange_info_multi())
  expect_identical(rep$status[rep$fact_family == "symbol_universe"], "absent")
  expect_identical(fact_grounding("binance", "symbol_universe"),
                   grounding_unverified())
})

test_that("a symbol absent from the catalogue is reported absent, not grounded", {
  .registry_init()
  rep <- bourse_catalogue_diff("binance", symbols = "DOGEUSDT",
                               exchange_info = .recorded_exchange_info())
  expect_identical(rep$status[rep$fact_family == "symbol_universe"], "absent")
  expect_identical(fact_grounding("binance", "symbol_universe"),
                   grounding_unverified())
})

test_that("after grounding, an OHLCV series is grounded", {
  .registry_init()
  bourse_catalogue_diff("binance", symbols = "BTCUSDT",
                        exchange_info = .recorded_exchange_info())
  s <- bourse_ohlcv("BTCUSDT", candles = cbind(1.5e12, 100, 105, 99, 102, 1200))
  expect_identical(s@grounding, grounding_grounded())
})

test_that("live catalogue grounds against the real authority", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  .registry_init()
  rep <- tryCatch(bourse_catalogue_diff("binance", symbols = "BTCUSDT"),
                  error = function(e) skip(conditionMessage(e)))
  expect_identical(rep$status[rep$fact_family == "tick_size"], "grounded")
})
