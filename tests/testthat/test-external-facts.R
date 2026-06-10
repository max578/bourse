test_that("the registry seeds every fact family un-grounded (honest NA)", {
  .registry_init()
  facts <- bourse_external_facts()
  expect_true(all(c("source", "fact_family", "asserted_value", "oracle_kind",
                    "verified_on", "evidence_path") %in% names(facts)))
  expect_true(nrow(facts) >= 7L)
  expect_true(all(is.na(facts$verified_on)))          # nothing fabricated
})

test_that("fact_status reports the un-grounded baseline", {
  .registry_init()
  st <- bourse_fact_status("binance")
  expect_identical(st$n_grounded, 0L)
  expect_true(st$n_unverified >= 7L)
})

test_that("fact_grounding reads the registry per family", {
  .registry_init()
  expect_identical(fact_grounding("binance", "tick_size"),
                   grounding_unverified())
  expect_identical(fact_grounding("binance", "no_such_family"),
                   grounding_unverified())
})
