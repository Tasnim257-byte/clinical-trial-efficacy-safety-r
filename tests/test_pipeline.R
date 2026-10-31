# Lightweight tests using base R (no testthat dependency).
source("R/helpers.R")
source("R/generate_synthetic_data.R")
source("R/analyze_efficacy.R")
source("R/analyze_safety.R")
source("R/power_simulation.R")

message("Validating bundled dataset...")
x <- read_trial()
stopifnot(nrow(x) == 600L, all(table(x$arm) == c(300L, 300L)))
stopifnot(isTRUE(validate_trial(x)))

message("Checking deterministic generator and field consistency...")
s1 <- simulate_trial(n = 100L, seed = 7L)
s2 <- simulate_trial(n = 100L, seed = 7L)
stopifnot(identical(s1, s2), isTRUE(validate_trial(s1)))

message("Checking validation catches incorrect event indicators...")
bad <- s1
bad$any_ae[1] <- 1L - bad$any_ae[1]
stopifnot(inherits(try(validate_trial(bad), silent = TRUE), "try-error"))

message("Checking efficacy and safety outputs...")
e <- analyze_efficacy(x)
s <- analyze_safety(x)
stopifnot(nrow(e$primary) == 1L, is.finite(e$primary$effect),
          e$primary$ci_lower <= e$primary$effect,
          e$primary$effect <= e$primary$ci_upper,
          e$sensitivity$n_analyzed == nrow(x),
          nrow(s$event_table) == 12L,
          all(s$event_table$risk >= 0 & s$event_table$risk <= 1),
          s$primary_safety$risk_difference >= -1,
          s$primary_safety$risk_difference <= 1)

message("Checking Monte Carlo is reproducible...")
p1 <- simulate_ancova_power(n_per_arm = 25L, reps = 25L, seed = 22L)
p2 <- simulate_ancova_power(n_per_arm = 25L, reps = 25L, seed = 22L)
stopifnot(identical(p1, p2), p1$rejection_rate >= 0, p1$rejection_rate <= 1)

message("All tests passed.")
