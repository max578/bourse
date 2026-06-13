# Recorded-real property oracle (recipe 52 section 5, oracle D). Asserts physical
# / structural invariants on the committed recorded-real Binance cassettes
# (fixtures/binance_*.json, hash-pinned in fixtures/PROVENANCE.md). These are the
# silent-escape facts (schema / units / enum): a wrong filter field or a
# mis-mapped column returns wrong output with NO error, so a property oracle on a
# REAL captured payload -- not a hand-authored fixture -- is what grounds them.
# The cassette is the independent oracle the code did not author.
#
# Family coverage (recipe 52 F14): this oracle grounds symbol_universe,
# tick_size, lot_size, min_notional, quote_base_currency, timestamp_tz,
# ohlcv_column_semantics, orderbook_column_semantics, and
# ticker_column_semantics.

.fixture_path <- function(name) testthat::test_path("fixtures", name)

test_that("the recorded-real cassettes match their pinned hashes (meta-oracle)", {
  # tools::md5sum is base R, so this tamper-evidence runs everywhere with no
  # added dependency; the sha256 in PROVENANCE.md is for external verification.
  # A silent re-record (e.g. one that reintroduced the legacy MIN_NOTIONAL name)
  # changes the hash and fails here -- the meta-oracle (recipe 52 section 8).
  expected <- c(
    binance_exchangeInfo_BTCUSDT.json = "e6f23b4bd5f3d1a652fe21d6b35cc1b7",
    binance_exchangeInfo_multi.json   = "da9eb072c62a39a7fcfa69078b606571",
    binance_klines_BTCUSDT_1d.json    = "f3830885f9afa9555d39be6d201d3519",
    binance_depth_BTCUSDT.json        = "be49abab6a4d68be4f2da38f27ad8caf",
    binance_ticker24hr_BTCUSDT.json   = "2e0d75f3dedeb9802320b89c431ca6b8")
  for (fname in names(expected)) {
    expect_identical(unname(tools::md5sum(.fixture_path(fname))),
                     expected[[fname]])
  }
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

test_that("the multi-symbol catalogue carries every core symbol's filters", {
  skip_if_not_installed("jsonlite")
  info <- jsonlite::fromJSON(
    .fixture_path("binance_exchangeInfo_multi.json"), simplifyVector = FALSE)
  syms <- vapply(info$symbols, function(s) s$symbol, character(1L))
  # symbol_universe: every grounded core symbol is present in one capture
  expect_true(all(.BOURSE_CORE_SYMBOLS %in% syms))

  for (s in info$symbols) {
    ft <- vapply(s$filters, function(f) f$filterType, character(1L))
    fl <- stats::setNames(s$filters, ft)
    # each symbol carries the three numeric filters + currencies, with the
    # current NOTIONAL name (not the legacy MIN_NOTIONAL)
    expect_true(all(c("PRICE_FILTER", "LOT_SIZE", "NOTIONAL") %in% ft))
    expect_false("MIN_NOTIONAL" %in% ft)
    expect_gt(as.numeric(fl[["PRICE_FILTER"]]$tickSize), 0)
    expect_gt(as.numeric(fl[["LOT_SIZE"]]$stepSize), 0)
    expect_gt(as.numeric(fl[["NOTIONAL"]]$minNotional), 0)
    expect_true(nzchar(s$baseAsset) && nzchar(s$quoteAsset))
  }
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

test_that("depth ladders carry the asserted orderbook_column_semantics", {
  skip_if_not_installed("jsonlite")
  d <- jsonlite::fromJSON(
    .fixture_path("binance_depth_BTCUSDT.json"), simplifyVector = FALSE)

  # the response is bids + asks, each a list of [price, qty] arrays
  expect_true(all(c("bids", "asks") %in% names(d)))
  expect_gt(length(d$bids), 0L)
  expect_gt(length(d$asks), 0L)
  lvl_shape <- function(side) {
    all(vapply(side, function(lv) length(lv) == 2L, logical(1L)))
  }
  expect_true(lvl_shape(d$bids) && lvl_shape(d$asks))

  bid_px <- vapply(d$bids, function(lv) as.numeric(lv[[1L]]), numeric(1L))
  bid_qy <- vapply(d$bids, function(lv) as.numeric(lv[[2L]]), numeric(1L))
  ask_px <- vapply(d$asks, function(lv) as.numeric(lv[[1L]]), numeric(1L))

  # orderbook_column_semantics: prices + quantities are positive finite numbers
  expect_true(all(is.finite(bid_px)) && all(bid_px > 0))
  expect_true(all(is.finite(bid_qy)) && all(bid_qy > 0))

  # structural invariant: a resting book is not crossed -- best bid < best ask.
  # This is the property that catches a transposed bids/asks ladder (the silent
  # failure a live call alone would not surface).
  expect_lt(max(bid_px), min(ask_px))
})

test_that("ticker24hr fields carry the asserted ticker_column_semantics", {
  skip_if_not_installed("jsonlite")
  tk <- jsonlite::fromJSON(
    .fixture_path("binance_ticker24hr_BTCUSDT.json"), simplifyVector = FALSE)

  expect_identical(tk$symbol, "BTCUSDT")
  needed <- c("lastPrice", "openPrice", "highPrice", "lowPrice", "volume",
              "quoteVolume", "openTime", "closeTime")
  expect_true(all(needed %in% names(tk)))

  last  <- as.numeric(tk$lastPrice)
  open  <- as.numeric(tk$openPrice)
  high  <- as.numeric(tk$highPrice)
  low   <- as.numeric(tk$lowPrice)
  vol   <- as.numeric(tk$volume)
  qvol  <- as.numeric(tk$quoteVolume)
  ot    <- as.numeric(tk$openTime)
  ct    <- as.numeric(tk$closeTime)

  # ticker_column_semantics: the high/low envelope bounds last + open, volumes
  # are positive, and the window is a 13-digit ms-epoch span (open < close).
  # A transposed high/low or a mis-mapped column breaks one of these.
  expect_true(high >= low)
  expect_true(last >= low && last <= high)
  expect_true(open >= low && open <= high)
  expect_gt(vol, 0)
  expect_gt(qvol, 0)
  expect_true(ot > 1e12 && ot < 4e12)
  expect_gt(ct, ot)
})
