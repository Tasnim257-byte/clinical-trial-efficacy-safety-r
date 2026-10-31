# Shared utilities for the synthetic randomized trial portfolio project.
# Only base R is required.

required_trial_columns <- c(
  "participant_id", "site", "arm", "age", "sex", "baseline_score",
  "week12_score", "responder", "ae_headache", "ae_nausea",
  "ae_fatigue", "ae_rash", "any_ae", "serious_ae"
)

read_trial <- function(path = "data/synthetic_trial.csv") {
  if (!file.exists(path)) stop("Trial CSV not found: ", path, call. = FALSE)
  x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  validate_trial(x)
  x$arm <- factor(x$arm, levels = c("Control", "Treatment"))
  x$site <- factor(x$site)
  x$sex <- factor(x$sex)
  x
}

validate_trial <- function(x) {
  missing_cols <- setdiff(required_trial_columns, names(x))
  if (length(missing_cols)) stop("Missing columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  if (nrow(x) == 0L) stop("The trial dataset is empty.", call. = FALSE)
  if (anyNA(x$participant_id) || anyDuplicated(x$participant_id))
    stop("participant_id must be unique and nonmissing.", call. = FALSE)
  if (anyNA(x$arm) || !all(x$arm %in% c("Control", "Treatment")))
    stop("arm must be Control or Treatment, without missing values.", call. = FALSE)
  if (!all(c("Control", "Treatment") %in% x$arm))
    stop("Both randomized treatment groups are required.", call. = FALSE)
  if (anyNA(x$site) || anyNA(x$sex) || anyNA(x$age) || anyNA(x$baseline_score))
    stop("Baseline characteristics must not be missing.", call. = FALSE)
  if (any(!x$sex %in% c("Female", "Male"))) stop("Unexpected sex category.", call. = FALSE)
  if (any(x$age < 18 | x$age > 85)) stop("age outside expected range.", call. = FALSE)
  if (any(x$baseline_score < 0 | x$baseline_score > 100))
    stop("baseline_score must be in [0, 100].", call. = FALSE)
  if (any(x$week12_score < 0 | x$week12_score > 100, na.rm = TRUE))
    stop("week12_score must be in [0, 100].", call. = FALSE)
  for (nm in c("responder", "ae_headache", "ae_nausea", "ae_fatigue", "ae_rash", "any_ae", "serious_ae")) {
    if (!all(x[[nm]][!is.na(x[[nm]])] %in% c(0, 1)))
      stop(nm, " must be 0 or 1 (NA allowed only for responder).", call. = FALSE)
  }
  ae_cols <- c("ae_headache", "ae_nausea", "ae_fatigue", "ae_rash", "any_ae", "serious_ae")
  if (anyNA(x[, ae_cols])) stop("Safety event indicators must be complete.", call. = FALSE)
  if (any(x$any_ae != as.integer(rowSums(x[, ae_cols[1:4]]) > 0)))
    stop("any_ae inconsistent with individual event flags.", call. = FALSE)
  if (any(x$serious_ae > x$any_ae)) stop("serious_ae must imply any_ae.", call. = FALSE)
  if (any(is.na(x$responder) != is.na(x$week12_score)))
    stop("responder must be missing exactly when week12_score is missing.", call. = FALSE)
  if (any(x$responder[!is.na(x$responder)] != as.integer((x$baseline_score - x$week12_score)[!is.na(x$responder)] >= 12)))
    stop("responder does not match the prespecified >=12-point threshold.", call. = FALSE)
  invisible(TRUE)
}

wilson_interval <- function(events, n, z = qnorm(0.975)) {
  stopifnot(n > 0L, events >= 0L, events <= n)
  p <- events / n
  den <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / den
  rad <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  c(lower = max(0, ctr - rad), upper = min(1, ctr + rad))
}

write_table <- function(x, filename) {
  dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
  write.csv(x, file.path("outputs/tables", filename), row.names = FALSE, na = "")
  invisible(x)
}
