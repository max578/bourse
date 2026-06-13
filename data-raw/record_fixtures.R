# record_fixtures.R -- re-ground bourse's recorded-real Binance cassettes.
#
# Run interactively (needs network) to re-capture the recorded-real fixtures the
# oracle tests replay. This is the recipe-52 section-7 re-grounding script: it
# hits the live authority, rewrites the committed cassettes, and prints the new
# sha256 + md5 so PROVENANCE.md and the hash literals in the oracle tests
# (test-properties-recorded.R, test-catalogue-diff.R) can be updated in lockstep.
# It fetches only anonymous, public market-metadata endpoints (no API key, no
# account data).
#
#   Rscript data-raw/record_fixtures.R

if (!requireNamespace("httr2", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
  stop("record_fixtures.R needs 'httr2' + 'jsonlite' installed.", call. = FALSE)
}

fixtures <- file.path("tests", "testthat", "fixtures")
dir.create(fixtures, showWarnings = FALSE, recursive = TRUE)

# The grounded multi-symbol universe. A single /exchangeInfo call with a JSON
# `symbols` array captures all four at once, so one cassette grounds the filters
# (tickSize / stepSize / NOTIONAL) of every symbol against the live catalogue.
grounded_symbols <- c("BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT")
symbols_json <- jsonlite::toJSON(grounded_symbols)

endpoints <- list(
  # Re-grounded single-symbol catalogue (back-compat with the 0.0.0 oracle).
  binance_exchangeInfo_BTCUSDT.json =
    "https://api.binance.com/api/v3/exchangeInfo?symbol=BTCUSDT",
  # Multi-symbol catalogue: grounds the four-symbol universe in one capture.
  binance_exchangeInfo_multi.json =
    paste0("https://api.binance.com/api/v3/exchangeInfo?symbols=",
           utils::URLencode(symbols_json, reserved = TRUE)),
  # Re-grounded klines.
  binance_klines_BTCUSDT_1d.json =
    "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=2",
  # Order book (read-only) -- top of book for the depth verb.
  binance_depth_BTCUSDT.json =
    "https://api.binance.com/api/v3/depth?symbol=BTCUSDT&limit=5",
  # 24h rolling-window ticker (read-only) for the ticker verb.
  binance_ticker24hr_BTCUSDT.json =
    "https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT"
)

for (fname in names(endpoints)) {
  resp <- httr2::req_perform(httr2::request(endpoints[[fname]]))
  # Write the authority's exact response bytes -- the recorded-real ideal is the
  # real payload, not a re-encoding of it. (jsonlite is only required so the
  # round-trip parse below confirms the capture is well-formed before it lands.)
  invisible(jsonlite::fromJSON(httr2::resp_body_string(resp),
                               simplifyVector = FALSE))
  path <- file.path(fixtures, fname)
  writeBin(httr2::resp_body_raw(resp), path)
  message(sprintf("%-36s captured_on=%s", fname, format(Sys.Date())))
  message(sprintf("  sha256 = %s",
                  if (requireNamespace("digest", quietly = TRUE))
                    digest::digest(file = path, algo = "sha256") else
                      "(install 'digest')"))
  message(sprintf("  md5    = %s", unname(tools::md5sum(path))))
}

message("\nUpdate fixtures/PROVENANCE.md (captured_on + sha256 + md5) and the md5 ",
        "literals asserted in tests/testthat/test-properties-recorded.R + the ",
        "guard hash in tests/testthat/test-catalogue-diff.R.")
