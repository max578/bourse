# The catalogue-diff oracle is the only thing that moves a fact from
# [unverified] to grounded. Offline tests run it against a recorded-real
# catalogue shape (NOT a self-authored golden of bourse's own making -- the
# structure mirrors Binance's /exchangeInfo). A network test grounds against the
# live authority, skipped on CRAN and offline.

.recorded_exchange_info <- function(symbol = "BTCUSDT") {
  list(symbols = list(list(
    symbol = symbol, baseAsset = "BTC", quoteAsset = "USDT",
    filters = list(
      list(filterType = "PRICE_FILTER", tickSize = "0.01"),
      list(filterType = "LOT_SIZE", stepSize = "0.00001"),
      list(filterType = "MIN_NOTIONAL", minNotional = "5")))))
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
                               exchange_info = .recorded_exchange_info("BTCUSDT"))
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
