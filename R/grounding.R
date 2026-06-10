# =============================================================================
# Provenance vocabulary (Independent Oracle Principle)
# =============================================================================
# The canonical grounding tokens, hardcoded to match the ORCHESTRA federation
# (`integration/provenance_vocabulary.md`). A market fact -- a symbol, a tick
# size, a fee, a column's unit -- is `grounded` only once it has been diffed
# against the exchange catalogue that owns it. Everything else is `[unverified]`
# and, on a live order path, must be refused rather than acted on. For a trading
# connector this is not bookkeeping: an unverified tick size or fee is a silently
# wrong number that loses money.

#' Canonical grounding tokens
#'
#' The two states a market fact can occupy under the Independent Oracle
#' Principle. `grounding_grounded()` is the token for a fact diffed against the
#' exchange catalogue that owns it; `grounding_unverified()` is the default for
#' everything else. The brackets in `"[unverified]"` are load-bearing: they make
#' an un-grounded label unmissable wherever it surfaces.
#'
#' @return A length-one character string holding the canonical token.
#' @examples
#' grounding_grounded()
#' grounding_unverified()
#' @family grounding
#' @name grounding_tokens
NULL

#' @rdname grounding_tokens
#' @export
grounding_grounded <- function() "grounded"

#' @rdname grounding_tokens
#' @export
grounding_unverified <- function() "[unverified]"

#' Combine grounding worst-case
#'
#' A series (or a decision) built from several facts is grounded only when every
#' fact is grounded; one un-grounded fact taints the whole. Tokens are validated
#' against the canonical vocabulary so a synonym is rejected rather than silently
#' mistaken for grounded.
#'
#' @param tokens A character vector of grounding tokens.
#' @return `grounding_grounded()` if non-empty and all grounded, else
#'   `grounding_unverified()`.
#' @examples
#' combine_grounding(c(grounding_grounded(), grounding_unverified()))
#' @family grounding
#' @export
combine_grounding <- function(tokens) {
  tokens <- as.character(tokens)
  ok <- tokens %in% c(grounding_grounded(), grounding_unverified())
  if (!all(ok)) {
    bad <- unique(tokens[!ok])
    stop(sprintf("non-canonical grounding token(s): %s",
                 paste(sQuote(bad), collapse = ", ")), call. = FALSE)
  }
  if (length(tokens) == 0L || any(tokens == grounding_unverified())) {
    grounding_unverified()
  } else {
    grounding_grounded()
  }
}

.is_grounded <- function(token) {
  identical(as.character(token), grounding_grounded())
}
