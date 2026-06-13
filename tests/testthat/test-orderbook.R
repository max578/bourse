# The depth verb: offline parse of a recorded-style payload, the refusal paths,
# and grounding propagation. The recorded-real property oracle for the depth
# response shape lives in test-properties-recorded.R.

.fixture_depth <- function() {
  list(
    lastUpdateId = 42,
    bids = list(c("100.0", "1.5"), c("99.9", "2.0")),
    asks = list(c("100.1", "1.0"), c("100.2", "3.0")))
}

test_that("a recorded depth payload parses into an order_book", {
  .registry_init()
  ob <- bourse_orderbook("BTCUSDT", depth = .fixture_depth())
  expect_true(S7::S7_inherits(ob, order_book))
  expect_identical(ob@symbol, "BTCUSDT")
  expect_identical(nrow(ob@bids), 2L)
  expect_identical(nrow(ob@asks), 2L)
  expect_identical(ob@last_update_id, 42)
  expect_true(all(c("price", "qty") %in% names(ob@bids)))
})

test_that("a parsed book is [unverified] until the catalogue is diffed", {
  .registry_init()
  ob <- bourse_orderbook("BTCUSDT", depth = .fixture_depth())
  expect_identical(ob@grounding, grounding_unverified())
  expect_identical(unique(ob@obs_schema$grounding), grounding_unverified())
})

test_that("after grounding, an order book is grounded", {
  .registry_init()
  info <- list(symbols = list(list(
    symbol = "BTCUSDT", baseAsset = "BTC", quoteAsset = "USDT",
    filters = list(
      list(filterType = "PRICE_FILTER", tickSize = "0.01"),
      list(filterType = "LOT_SIZE", stepSize = "0.00001"),
      list(filterType = "NOTIONAL", minNotional = "5")))))
  bourse_catalogue_diff("binance", symbols = "BTCUSDT", exchange_info = info)
  ob <- bourse_orderbook("BTCUSDT", depth = .fixture_depth())
  expect_identical(ob@grounding, grounding_grounded())
})

test_that("an unknown source is refused, not faked", {
  r <- bourse_orderbook("BTCUSDT", depth = .fixture_depth(), source = "nasdaq")
  expect_true(is_refusal(r))
  expect_identical(r@reason, "unknown_source")
})

test_that("a crossed book is refused, not returned", {
  crossed <- list(bids = list(c("101.0", "1.0")), asks = list(c("100.0", "1.0")))
  r <- bourse_orderbook("BTCUSDT", depth = crossed)
  expect_true(is_refusal(r))
  expect_identical(r@reason, "crossed_book")
})

test_that("an empty or malformed book is refused", {
  r1 <- bourse_orderbook("BTCUSDT", depth = list(bids = list(), asks = list()))
  expect_true(is_refusal(r1))
  expect_identical(r1@reason, "malformed_depth")

  r2 <- bourse_orderbook("BTCUSDT",
                         depth = list(bids = list("100.0"), asks = list("101.0")))
  expect_true(is_refusal(r2))
  expect_identical(r2@reason, "malformed_depth")
})

test_that("the order_book validator rejects a crossed or mis-shaped book", {
  expect_error(
    order_book(bids = data.frame(price = 101, qty = 1),
               asks = data.frame(price = 100, qty = 1),
               grounding = grounding_unverified()),
    "crossed book")
  expect_error(
    order_book(bids = data.frame(p = 1, q = 1),
               grounding = grounding_unverified()),
    "price.*qty")
})
