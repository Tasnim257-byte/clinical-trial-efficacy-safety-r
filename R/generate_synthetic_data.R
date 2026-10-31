# Regenerate a *synthetic* teaching dataset. No real patient data are used.
# Running Rscript R/generate_synthetic_data.R overwrites data/synthetic_trial.csv.

simulate_trial <- function(n = 600L, seed = 20271031L) {
  if (length(n) != 1 || is.na(n) || n < 20 || n %% 2 != 0)
    stop("n must be an even integer >= 20.", call. = FALSE)
  set.seed(seed)
  arm <- sample(rep(c("Control", "Treatment"), each = n / 2L))
  treated <- as.integer(arm == "Treatment")
  site <- sample(sprintf("Site_%02d", 1:6), n, replace = TRUE)
  age <- pmin(85L, pmax(18L, round(rnorm(n, 55, 12))))
  sex <- sample(c("Female", "Male"), n, replace = TRUE, prob = c(0.54, 0.46))
  baseline <- round(pmin(100, pmax(10, rnorm(n, 65, 11))), 1)
  site_effect <- setNames(c(-0.8, -0.3, 0.1, 0.6, 0.5, -0.1), sprintf("Site_%02d", 1:6))
  improvement <- 8 + 4.5 * treated + 0.04 * (baseline - 65) -
    0.40 * (age - 55) / 12 + site_effect[site] + rnorm(n, 0, 9)
  week12 <- round(pmin(100, pmax(0, baseline - improvement)), 1)
  # Some week-12 outcomes are missing; not all reasons are observed.
  drop_prob <- plogis(-2.9 + 0.015 * (baseline - 65) + 0.15 * treated)
  week12[runif(n) < drop_prob] <- NA_real_
  responder <- ifelse(is.na(week12), NA_integer_, as.integer(baseline - week12 >= 12))

  headache <- rbinom(n, 1, ifelse(treated == 1, 0.16, 0.12))
  nausea <- rbinom(n, 1, ifelse(treated == 1, 0.13, 0.07))
  fatigue <- rbinom(n, 1, ifelse(treated == 1, 0.12, 0.13))
  rash <- rbinom(n, 1, ifelse(treated == 1, 0.09, 0.04))
  any_ae <- as.integer(headache + nausea + fatigue + rash > 0)
  serious_ae <- as.integer(any_ae == 1 & runif(n) < ifelse(treated == 1, 0.04, 0.025))
  data.frame(
    participant_id = sprintf("P%04d", seq_len(n)), site = site, arm = arm,
    age = as.integer(age), sex = sex, baseline_score = baseline,
    week12_score = week12, responder = responder,
    ae_headache = headache, ae_nausea = nausea, ae_fatigue = fatigue,
    ae_rash = rash, any_ae = any_ae, serious_ae = serious_ae,
    stringsAsFactors = FALSE
  )
}

if (sys.nframe() == 0L) {
  source("R/helpers.R")
  dir.create("data", recursive = TRUE, showWarnings = FALSE)
  dataset <- simulate_trial()
  validate_trial(dataset)
  write.csv(dataset, "data/synthetic_trial.csv", row.names = FALSE, na = "")
  cat(sprintf("Saved %s synthetic trial participants.\n", nrow(dataset)))
}
