# Monte Carlo operating characteristics of a simplified ANCOVA trial design.
# This is not a prospective clinical trial sample-size calculation.

simulate_ancova_power <- function(
    n_per_arm = 300L, true_treatment_effect = -4.5,
    outcome_sd = 9, reps = 200L, seed = 20271031L, alpha = 0.05) {
  stopifnot(n_per_arm >= 10, reps >= 20, outcome_sd > 0, alpha > 0, alpha < 1)
  set.seed(seed)
  significant <- replicate(reps, {
    treatment <- rep(c(0L, 1L), each = n_per_arm)
    baseline <- rnorm(2 * n_per_arm, 65, 11)
    followup <- 14 + 0.66 * baseline + true_treatment_effect * treatment +
      rnorm(2 * n_per_arm, 0, outcome_sd)
    fit <- lm(followup ~ treatment + baseline)
    p <- summary(fit)$coefficients["treatment", "Pr(>|t|)"]
    is.finite(p) && p < alpha
  })
  rate <- mean(significant)
  data.frame(
    n_per_arm = n_per_arm, treatment_effect = true_treatment_effect,
    outcome_sd = outcome_sd, replications = reps, alpha = alpha,
    rejection_rate = rate, mc_se = sqrt(rate * (1 - rate) / reps)
  )
}

run_power_scenarios <- function() {
  # Null rejection rate should be near alpha; alternative rejection rate is
  # estimated power, under the *simulation assumptions* stated in the protocol.
  rbind(
    simulate_ancova_power(true_treatment_effect = 0, seed = 101L),
    simulate_ancova_power(true_treatment_effect = -2.5, seed = 102L),
    simulate_ancova_power(true_treatment_effect = -4.5, seed = 103L)
  )
}

if (sys.nframe() == 0L) {
  source("R/helpers.R")
  x <- run_power_scenarios()
  write_table(x, "simulation_operating_characteristics.csv")
  print(x)
}
