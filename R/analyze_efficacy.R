# Prespecified efficacy endpoints for a simulated parallel-group trial.
# Lower symptom burden scores indicate better outcomes.

analyze_efficacy <- function(trial) {
  validate_trial(trial)
  trial$arm <- factor(as.character(trial$arm), levels = c("Control", "Treatment"))
  trial$site <- factor(trial$site)
  trial$sex <- factor(trial$sex)
  observed <- trial[!is.na(trial$week12_score), , drop = FALSE]
  if (sum(observed$arm == "Control") < 2 || sum(observed$arm == "Treatment") < 2)
    stop("Not enough observed efficacy outcomes in both arms.", call. = FALSE)
  observed$change <- observed$week12_score - observed$baseline_score

  # Primary exploratory efficacy model: complete-case ANCOVA with adjustment.
  fit <- lm(week12_score ~ arm + baseline_score + age + sex + site, data = observed)
  term <- "armTreatment"
  if (!term %in% names(coef(fit))) stop("Treatment coefficient missing.", call. = FALSE)
  ci <- confint(fit, parm = term, level = 0.95)
  sm <- summary(fit)$coefficients
  primary <- data.frame(
    analysis = "Observed-case ANCOVA", n_analyzed = nobs(fit),
    effect = unname(coef(fit)[term]), ci_lower = unname(ci[1]),
    ci_upper = unname(ci[2]), p_value = unname(sm[term, "Pr(>|t|)"])
  )

  # Sensitivity: replace missing week-12 values with baseline (no improvement).
  # BOCF is simplistic; it is NOT multiple imputation and is not an MAR remedy.
  sensitivity <- trial
  sensitivity$week12_score[is.na(sensitivity$week12_score)] <-
    sensitivity$baseline_score[is.na(sensitivity$week12_score)]
  fit_sens <- lm(week12_score ~ arm + baseline_score + age + sex + site, data = sensitivity)
  sens_ci <- confint(fit_sens, parm = term, level = 0.95)
  sensitivity_result <- data.frame(
    analysis = "Baseline observation carried forward (sensitivity)",
    n_analyzed = nobs(fit_sens), effect = unname(coef(fit_sens)[term]),
    ci_lower = unname(sens_ci[1]), ci_upper = unname(sens_ci[2]),
    p_value = unname(summary(fit_sens)$coefficients[term, "Pr(>|t|)"])
  )

  # Secondary binary responder analysis, among participants with outcome observed.
  # The responder threshold is >=12 points of symptom improvement at week 12.
  resp_fit <- glm(responder ~ arm + baseline_score + age + sex + site,
                  data = observed, family = binomial())
  resp_coef <- summary(resp_fit)$coefficients[term, ]
  # Wald CI: transparent and stable for this demonstration. May be poor in sparse data.
  resp_ci <- resp_coef["Estimate"] + c(-1, 1) * qnorm(0.975) * resp_coef["Std. Error"]
  responder <- data.frame(
    analysis = "Observed-case adjusted responder odds ratio",
    n_analyzed = nobs(resp_fit), odds_ratio = unname(exp(resp_coef["Estimate"])),
    ci_lower = unname(exp(resp_ci[1])), ci_upper = unname(exp(resp_ci[2])),
    p_value = unname(resp_coef["Pr(>|z|)"])
  )

  arm_summary <- do.call(rbind, lapply(levels(trial$arm), function(a) {
    d <- trial[trial$arm == a, , drop = FALSE]
    o <- d[!is.na(d$week12_score), , drop = FALSE]
    data.frame(
      arm = a, randomized_n = nrow(d), missing_week12_n = nrow(d) - nrow(o),
      mean_baseline = mean(d$baseline_score), mean_week12 = mean(o$week12_score),
      mean_change = mean(o$week12_score - o$baseline_score),
      responders_n = sum(o$responder), responder_rate = mean(o$responder)
    )
  }))

  list(primary = primary, sensitivity = sensitivity_result,
       responder = responder, arm_summary = arm_summary,
       primary_model = fit, responder_model = resp_fit)
}

if (sys.nframe() == 0L) {
  source("R/helpers.R")
  res <- analyze_efficacy(read_trial())
  write_table(res$primary, "efficacy_primary.csv")
  write_table(res$sensitivity, "efficacy_sensitivity.csv")
  write_table(res$responder, "efficacy_responder.csv")
  write_table(res$arm_summary, "efficacy_arm_summary.csv")
  writeLines(capture.output(summary(res$primary_model)), "outputs/tables/efficacy_model.txt")
  print(res$primary)
}
