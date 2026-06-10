test_that("canonical tokens match the federation strings", {
  expect_identical(grounding_grounded(), "grounded")
  expect_identical(grounding_unverified(), "[unverified]")
})

test_that("combine_grounding is worst-case and rejects synonyms", {
  g <- grounding_grounded()
  u <- grounding_unverified()
  expect_identical(combine_grounding(c(g, g)), g)
  expect_identical(combine_grounding(c(g, u)), u)
  expect_identical(combine_grounding(character(0L)), u)
  expect_error(combine_grounding("ungrounded"), "non-canonical")
})
