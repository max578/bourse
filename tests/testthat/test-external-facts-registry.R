# The canonical recipe-52 registry (.external_facts) + its validator
# (.validate_external_registry, gate F13/F14). The seed and the canonical
# registry must describe the same families (one source of truth, no drift), and
# the validator must report the HONEST grounded / un-grounded state per family --
# never a fabricated pass. fee_schedule is un-grounded by design; the test
# asserts the validator says so rather than papering it over.

test_that("the canonical registry and the runtime seed describe the same families", {
  expect_setequal(.external_facts$family, .bourse_facts_seed()$fact_family)
  # asserted values carried through unchanged (the seed is the single source)
  expect_identical(.external_facts$value, .bourse_facts_seed()$asserted_value)
  # canonical recipe-52 columns are all present
  expect_true(all(c("family", "fact_id", "kind", "value", "source",
                    "verified_on", "reverify_by", "oracle_types", "signoff")
                  %in% names(.external_facts)))
})

test_that("the validator grounds the cassette-backed families and flags fee_schedule honestly", {
  res <- .validate_external_registry(test_dir = testthat::test_path())
  grounded <- c("symbol_universe", "tick_size", "lot_size", "min_notional",
                "quote_base_currency", "timestamp_tz", "ohlcv_column_semantics",
                "orderbook_column_semantics", "ticker_column_semantics")
  expect_true(all(res$pass[res$family %in% grounded]))
  # fee_schedule (auth-gated /sapi tradeFee, unimplemented) is genuinely
  # un-grounded -> honest fail, surfaced, never silently passed.
  expect_false(res$pass[res$family == "fee_schedule"])
  expect_match(res$reason[res$family == "fee_schedule"], "unverified")
})

test_that("every grounded silent-kind family declares a D/E/F oracle (recipe 52 §2)", {
  # silent kinds (schema/enum/units/constant) escape silently, so a grounded one
  # must carry a property/differential/human oracle, not just a live call.
  silent_grounded <- .external_facts$kind %in% .silent_fact_kinds &
    !is.na(.external_facts$verified_on)
  expect_true(all(grepl("[DEF]", .external_facts$oracle_types[silent_grounded])))
})
