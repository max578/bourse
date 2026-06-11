# The catalogue-diff oracle is the only thing that moves a fact from
# [unverified] to grounded. The offline tests replay a RECORDED-REAL Binance
# /exchangeInfo response captured from the live authority
# (fixtures/binance_exchangeInfo_BTCUSDT.json, hash-pinned in
# fixtures/PROVENANCE.md) -- NOT a hand-authored golden of bourse's own making,
# which is the circular mock that let the legacy `MIN_NOTIONAL` name ride green
# until the round-3 grounding audit caught it against the live authority. A
# separate network test grounds against the live authority (skipped on CRAN /
# offline).

.recorded_exchange_info <- function() {
  skip_if_not_installed("jsonlite")
  path <- testthat::test_path("fixtures", "binance_exchangeInfo_BTCUSDT.json")
  # Meta-oracle (recipe 52 §8): a silent re-record changes the hash and fails
  # here, so a fixture can never quietly drift away from the real authority.
  if (!identical(unname(tools::md5sum(path)),
                 "9a468c45aa53a3a7783fc31b68ac5528")) {
    stop("recorded cassette hash drift: re-run data-raw/record_fixtures.R and ",
         "update PROVENANCE.md + the asserted hashes.", call. = FALSE)
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
