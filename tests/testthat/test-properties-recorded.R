# Recorded-real property oracle (recipe 52 §5, oracle D). Asserts physical /
# structural invariants on the committed recorded-real Binance cassettes
# (fixtures/binance_*BTCUSDT*.json, hash-pinned in fixtures/PROVENANCE.md). These
# are the silent-escape facts (schema / units / enum): a wrong filter field or a
# mis-mapped kline column returns wrong output with NO error, so a property
# oracle on a REAL captured payload -- not a hand-authored fixture -- is what
# grounds them. The cassette is the independent oracle the code did not author.
#
# Family coverage (recipe 52 F14): this oracle grounds symbol_universe,
# tick_size, lot_size, min_notional, quote_base_currency, timestamp_tz, and
# ohlcv_column_semantics.

.fixture_path <- function(name) testthat::test_path("fixtures", name)

test_that("the recorded-real cassettes match their pinned hashes (meta-oracle)", {
  # tools::md5sum is base R, so this tamper-evidence runs everywhere with no
  # added dependency; the sha256 in PROVENANCE.md is for external verification.
  # A silent re-record (e.g. one that reintroduced the legacy MIN_NOTIONAL name)
  # changes the hash and fails here -- the meta-oracle (recipe 52 §8).
  expect_identical(
    unname(tools::md5sum(.fixture_path("binance_exchangeInfo_BTCUSDT.json"))),
    "9a468c45aa53a3a7783fc31b68ac5528")
  expect_identical(
    unname(tools::md5sum(.fixture_path("binance_klines_BTCUSDT_1d.json"))),
    "2a99841bd15154e57ad1d0489e3cd702")
})

test_that("exchangeInfo filters carry the asserted schema + plausible values", {
  skip_if_not_installed("jsonlite")
  info <- jsonlite::fromJSON(
    .fixture_path("binance_exchangeInfo_BTCUSDT.json"), simplifyVector = FALSE)
  sym <- info$symbols[[1L]]

  # symbol_universe + quote_base_currency
  expect_identical(sym$symbol, "BTCUSDT")
  expect_true(nzchar(sym$baseAsset) && nzchar(sym$quoteAsset))

  ft <- vapply(sym$filters, function(f) f$filterType, character(1L))
  fl <- stats::setNames(sym$filters, ft)

  # tick_size: PRICE_FILTER.tickSize is a positive, finite number
  expect_true("PRICE_FILTER" %in% ft)
  expect_gt(as.numeric(fl[["PRICE_FILTER"]]$tickSize), 0)

  # lot_size: LOT_SIZE.stepSize positive
  expect_true("LOT_SIZE" %in% ft)
  expect_gt(as.numeric(fl[["LOT_SIZE"]]$stepSize), 0)

  # min_notional: the CURRENT spot filter is NOTIONAL.minNotional, NOT the legacy
  # MIN_NOTIONAL (the round-3 grounding correction). Assert both the corrected
  # belief and a plausible value.
  expect_true("NOTIONAL" %in% ft)
  expect_false("MIN_NOTIONAL" %in% ft)
  expect_gt(as.numeric(fl[["NOTIONAL"]]$minNotional), 0)
})

test_that("kline columns carry the asserted OHLCV semantics + ms-epoch time", {
  skip_if_not_installed("jsonlite")
  k <- jsonlite::fromJSON(
    .fixture_path("binance_klines_BTCUSDT_1d.json"), simplifyVector = FALSE)
  row <- k[[1L]]

  # ohlcv_column_semantics: a 12-element array, cols 1..6 =
  # openTime, open, high, low, close, volume(base)
  expect_length(row, 12L)
  open_time <- as.numeric(row[[1L]])
  o     <- as.numeric(row[[2L]])
  high  <- as.numeric(row[[3L]])
  low   <- as.numeric(row[[4L]])
  close <- as.numeric(row[[5L]])
  vol   <- as.numeric(row[[6L]])
  close_time <- as.numeric(row[[7L]])

  # OHLC ordering is the property that catches a column transposition
  expect_true(high >= max(o, close))
  expect_true(low  <= min(o, close))
  expect_gt(vol, 0)

  # timestamp_tz: open/close time are 13-digit ms since epoch (UTC), open < close
  expect_true(open_time > 1e12 && open_time < 4e12)
  expect_gt(close_time, open_time)
})
