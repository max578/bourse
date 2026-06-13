# The ticker verb: offline parse of a recorded-style payload, the refusal paths,
# and grounding propagation. The recorded-real property oracle for the
# ticker/24hr response shape lives in test-properties-recorded.R.

.fixture_ticker <- function() {
  list(
    symbol = "BTCUSDT", lastPrice = "100.0", openPrice = "98.0",
    highPrice = "101.0", lowPrice = "97.0", priceChange = "2.0",
    priceChangePercent = "2.04", weightedAvgPrice = "99.0",
    volume = "1200", quoteVolume = "118800",
    openTime = 1.5e12, closeTime = 1.5e12 + 86400000)
}

test_that("a recorded ticker payload parses into a market_ticker", {
  .registry_init()
  tk <- bourse_ticker("BTCUSDT", ticker = .fixture_ticker())
  expect_true(S7::S7_inherits(tk, market_ticker))
  expect_identical(tk@symbol, "BTCUSDT")
  expect_identical(tk@stats$last_price, 100)
  expect_identical(tk@stats$high_price, 101)
  expect_identical(tk@stats$low_price, 97)
  # the camelCase authority keys are mapped to snake_case fields
  expect_true(all(c("last_price", "open_price", "high_price", "low_price",
                    "volume", "quote_volume", "open_time", "close_time") %in%
                    names(tk@stats)))
})

test_that("a parsed ticker is [unverified] until the catalogue is diffed", {
  .registry_init()
  tk <- bourse_ticker("BTCUSDT", ticker = .fixture_ticker())
  expect_identical(tk@grounding, grounding_unverified())
  expect_identical(unique(tk@obs_schema$grounding), grounding_unverified())
})

test_that("after grounding, a ticker is grounded", {
  .registry_init()
  info <- list(symbols = list(list(
    symbol = "BTCUSDT", baseAsset = "BTC", quoteAsset = "USDT",
    filters = list(
      list(filterType = "PRICE_FILTER", tickSize = "0.01"),
      list(filterType = "LOT_SIZE", stepSize = "0.00001"),
      list(filterType = "NOTIONAL", minNotional = "5")))))
  bourse_catalogue_diff("binance", symbols = "BTCUSDT", exchange_info = info)
  tk <- bourse_ticker("BTCUSDT", ticker = .fixture_ticker())
  expect_identical(tk@grounding, grounding_grounded())
})

test_that("an unknown source is refused, not faked", {
  r <- bourse_ticker("BTCUSDT", ticker = .fixture_ticker(), source = "nasdaq")
  expect_true(is_refusal(r))
  expect_identical(r@reason, "unknown_source")
})

test_that("a ticker payload with none of the expected fields is refused", {
  r <- bourse_ticker("BTCUSDT", ticker = list(symbol = "BTCUSDT", foo = "1"))
  expect_true(is_refusal(r))
  expect_identical(r@reason, "malformed_ticker")
})

test_that("the obs_schema labels the percent and time fields distinctly", {
  .registry_init()
  tk <- bourse_ticker("BTCUSDT", ticker = .fixture_ticker())
  sch <- tk@obs_schema
  expect_identical(
    sch$unit[sch$name == "price_change_percent"], "percent")
  expect_identical(sch$unit[sch$name == "open_time"], "ms_utc")
})

test_that("the market_ticker validator rejects an inverted high/low envelope", {
  expect_error(
    market_ticker(stats = list(high_price = 90, low_price = 100),
                  grounding = grounding_unverified()),
    "high_price must not be below low_price")
})
