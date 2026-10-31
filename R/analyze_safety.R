# Descriptive treatment-emergent adverse event (TEAE) analysis.
# All randomized participants contribute to the synthetic safety denominator.

analyze_safety <- function(trial) {
  validate_trial(trial)
  arm <- as.character(trial$arm)
  endpoints <- c(
    "Any reported AE" = "any_ae",
    "Serious AE" = "serious_ae",
    "Headache" = "ae_headache",
    "Nausea" = "ae_nausea",
    "Fatigue" = "ae_fatigue",
    "Rash" = "ae_rash"
  )
  rows <- list()
  for (event_name in names(endpoints)) {
    col <- endpoints[[event_name]]
    for (a in c("Control", "Treatment")) {
      d <- trial[arm == a, , drop = FALSE]
      cases <- sum(d[[col]])
      ci <- wilson_interval(cases, nrow(d))
      rows[[length(rows) + 1L]] <- data.frame(
        event = event_name, arm = a, events_n = cases, total_n = nrow(d),
        risk = cases / nrow(d), risk_ci_lower = unname(ci[1]),
        risk_ci_upper = unname(ci[2])
      )
    }
  }
  event_table <- do.call(rbind, rows)
  trt <- trial[arm == "Treatment", , drop = FALSE]
  ctl <- trial[arm == "Control", , drop = FALSE]
  risk_trt <- mean(trt$any_ae)
  risk_ctl <- mean(ctl$any_ae)
  contingency <- matrix(c(
    sum(trt$any_ae), sum(1L - trt$any_ae),
    sum(ctl$any_ae), sum(1L - ctl$any_ae)
  ), nrow = 2, byrow = TRUE,
  dimnames = list(c("Treatment", "Control"), c("AE", "No AE")))
  primary_safety <- data.frame(
    endpoint = "Any reported AE", treatment_risk = risk_trt,
    control_risk = risk_ctl, risk_difference = risk_trt - risk_ctl,
    risk_ratio = if (risk_ctl == 0) NA_real_ else risk_trt / risk_ctl,
    fisher_p_value = fisher.test(contingency)$p.value
  )
  list(event_table = event_table, primary_safety = primary_safety)
}

if (sys.nframe() == 0L) {
  source("R/helpers.R")
  res <- analyze_safety(read_trial())
  write_table(res$event_table, "safety_events.csv")
  write_table(res$primary_safety, "safety_comparison.csv")
  print(res$primary_safety)
}
