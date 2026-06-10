.fixture_candles <- function() {
  cbind(open_time = c(1.5e12, 1.5e12 + 86400000),
        open = c(100, 102), high = c(105, 106), low = c(99, 101),
        close = c(102, 104), volume = c(1200, 1500))
}

test_that("a recorded fixture parses into a market_series", {
  .registry_init()
  s <- bourse_ohlcv("BTCUSDT", interval = "1d", candles = .fixture_candles())
  expect_true(S7::S7_inherits(s, market_series))
  expect_identical(nrow(s@data), 2L)
  expect_identical(s@symbol, "BTCUSDT")
  expect_true(all(c("open_time", "open", "high", "low", "close", "volume") %in%
                    names(s@data)))
})

test_that("a parsed series is [unverified] until the catalogue is diffed", {
  .registry_init()
  s <- bourse_ohlcv("BTCUSDT", candles = .fixture_candles())
  expect_identical(s@grounding, grounding_unverified())
  # the obs_schema carries the same grounding on its columns
  expect_identical(unique(s@obs_schema$grounding), grounding_unverified())
})

test_that("an unknown source is refused, not faked", {
  r <- bourse_ohlcv("BTCUSDT", candles = .fixture_candles(), source = "nasdaq")
  expect_true(is_refusal(r))
  expect_identical(r@reason, "unknown_source")
})

test_that("malformed candles are refused", {
  r <- bourse_ohlcv("BTCUSDT", candles = matrix(1:4, nrow = 1L))
  expect_true(is_refusal(r))
  expect_identical(r@reason, "malformed_candles")
})

test_that("is_refusal distinguishes the two outcomes", {
  s <- bourse_ohlcv("BTCUSDT", candles = .fixture_candles())
  expect_false(is_refusal(s))
  expect_true(is_refusal(bourse_refusal(reason = "x", detail = "y")))
})
