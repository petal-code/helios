#' @keywords internal
"_PACKAGE"

#' @importFrom dplyr %>% mutate
#' @importFrom graphics abline arrows par
#' @importFrom stats approxfun lm median predict rbinom rgamma rlnorm rnbinom
#'   rpois runif sd
#' @importFrom utils modifyList tail
NULL

# Data frame columns referenced without quotes. "index" is the typo
# reported in #166 and can go once that is fixed.
utils::globalVariables(c(
  "beta_total",
  "index",
  "type"
))
