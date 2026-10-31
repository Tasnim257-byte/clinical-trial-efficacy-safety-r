# Reproducible prostate cancer portfolio analysis and HTML report.
# Run from the GitHub repository root:
#   source("real_data/prostate_trial/run_prostate_report.R")
# This script loads only a public, historical dataset and writes outputs
# inside real_data/prostate_trial/outputs. No synthetic safety variables.

required <- c("Surrogate", "survival", "rmarkdown", "knitr")
missing_packages <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Install required packages first: install.packages(c(",
       paste(sprintf('"%s"', missing_packages), collapse = ", "), "))")
}
# Attach survival because the Cox formula uses its special strata() and tt() terms.
library(survival)

# Locate the script even when source() is called outside the project root.
this_script <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
if (!is.null(this_script) && file.exists(this_script)) {
  module_dir <- dirname(normalizePath(this_script))
} else if (file.exists("real_data/prostate_trial/prostate_report.Rmd")) {
  module_dir <- normalizePath("real_data/prostate_trial")
} else if (file.exists("prostate_report.Rmd")) {
  module_dir <- normalizePath(".")
} else {
  stop("Open the RStudio project first, then run source('real_data/prostate_trial/run_prostate_report.R').")
}
out_dir <- file.path(module_dir, "outputs")
fig_dir <- file.path(out_dir, "figures")
tab_dir <- file.path(out_dir, "tables")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

# Load public R package data, not data copied from a private clinical system.
dataset_env <- new.env(parent = emptyenv())
utils::data("prostate", package = "Surrogate", envir = dataset_env)
if (!exists("prostate", envir = dataset_env, inherits = FALSE)) {
  stop("Dataset 'prostate' was not loaded from package Surrogate.")
}
d <- get("prostate", envir = dataset_env)
needed <- c("TRIAL", "TREAT", "PSA", "SURVTIME", "SURVIND", "PATID")
stopifnot(all(needed %in% names(d)), nrow(d) == 412L,
          length(unique(d$TRIAL)) == 17L,
          all(d$TREAT %in% c(0,1)),
          all(d$SURVIND %in% c(0,1)),
          all(is.finite(d$SURVTIME)), all(d$SURVTIME > 0),
          !anyDuplicated(d[c("TRIAL", "PATID")]))
if (anyNA(d[, needed])) stop("Unexpected missing observations in source data.")
if (any(table(d$TRIAL, d$TREAT) == 0L)) stop("At least one trial lacks one treatment arm.")
d$arm <- factor(d$TREAT, levels = c(0,1), labels = c("Active control", "Experimental"))
d$trial <- factor(d$TRIAL)

fmt_p <- function(x) {
  ifelse(is.na(x), "NA", ifelse(x < 0.0001, "p < 0.0001", sprintf("p = %.4f", x)))
}
fmt <- function(x, digits = 3) {
  ifelse(is.na(x), "Not reached", formatC(x, digits = digits, format = "f"))
}

# Descriptives: the PSA scale is not described as raw ng/mL in the public docs.
by_arm <- do.call(rbind, lapply(levels(d$arm), function(g) {
  z <- d[d$arm == g, , drop = FALSE]
  data.frame(Group = g, Patients = nrow(z), Events = sum(z$SURVIND == 1),
             Censored = sum(z$SURVIND == 0), Mean_PSA = mean(z$PSA),
             Median_PSA = median(z$PSA), Median_observed_time = median(z$SURVTIME),
             check.names = FALSE)
}))
write.csv(by_arm, file.path(tab_dir, "study_summary.csv"), row.names = FALSE)

# PSA regression controlling for trial identity.
psa_model <- stats::lm(PSA ~ TREAT + factor(TRIAL), data = d)
psa_sum <- summary(psa_model)$coefficients["TREAT", ]
psa_ci <- stats::confint(psa_model, "TREAT", level = 0.95)
psa_table <- data.frame(
  Model = "PSA ~ treatment + trial fixed effects", N = nobs(psa_model),
  Difference = unname(psa_sum["Estimate"]),
  CI_low = unname(psa_ci[1]), CI_high = unname(psa_ci[2]),
  P_value = unname(psa_sum["Pr(>|t|)"])
)
write.csv(psa_table, file.path(tab_dir, "psa_regression.csv"), row.names = FALSE)

# Trial-pooled Kaplan-Meier curves are DESCRIPTIVE and not trial-adjusted.
km_model <- survival::survfit(survival::Surv(SURVTIME, SURVIND) ~ arm, data = d)
km_s <- summary(km_model)$table
km_table <- data.frame(Group = levels(d$arm), N = as.integer(km_s[,"records"]),
                       Events = as.integer(km_s[,"events"]),
                       Median_survival_time = unname(km_s[,"median"]))
write.csv(km_table, file.path(tab_dir,"kaplan_meier.csv"),row.names=FALSE)

# Stratified Cox model and Schoenfeld residual screening.
cox_model <- survival::coxph(survival::Surv(SURVTIME, SURVIND) ~ TREAT + strata(TRIAL),
                            data = d, ties = "efron", x = TRUE)
cox_s <- summary(cox_model)$coefficients["TREAT", ]
cox_ci <- summary(cox_model)$conf.int["TREAT", ]
cox_table <- data.frame(Model = "Trial-stratified Cox (constant HR)",
                        HR = unname(cox_ci["exp(coef)"]),
                        CI_low = unname(cox_ci["lower .95"]),
                        CI_high = unname(cox_ci["upper .95"]),
                        P_value = unname(cox_s["Pr(>|z|)"]))
ph <- survival::cox.zph(cox_model)
ph_p <- unname(ph$table["TREAT", "p"])
ph_table <- data.frame(Test = rownames(ph$table),
                       Chi_square = unname(ph$table[, "chisq"]),
                       P_value = unname(ph$table[, "p"]))
write.csv(cox_table, file.path(tab_dir,"cox_constant_hr.csv"),row.names=FALSE)
write.csv(ph_table, file.path(tab_dir,"proportional_hazards.csv"),row.names=FALSE)

# Exploratory log-time varying effect model (not a prespecified model).
time_model <- survival::coxph(
  survival::Surv(SURVTIME, SURVIND) ~ TREAT + tt(TREAT) + strata(TRIAL),
  data = d, ties = "efron", tt = function(x, t, ...) x * log(t))
time_coefs <- stats::coef(time_model)[c("TREAT", "tt(TREAT)")]
time_vcov <- stats::vcov(time_model)[c("TREAT", "tt(TREAT)"),
                                   c("TREAT", "tt(TREAT)"), drop=FALSE]
time_p <- summary(time_model)$coefficients["tt(TREAT)", "Pr(>|z|)"]
time_table <- data.frame(Effect = names(time_coefs),
                         Log_HR_coefficient = unname(time_coefs),
                         P_value = unname(summary(time_model)$coefficients[names(time_coefs), "Pr(>|z|)"]))
write.csv(time_table, file.path(tab_dir,"cox_time_varying.csv"),row.names=FALSE)

# Pointwise (not simultaneous) 95% model-based uncertainty for HR(t).
# Restrict to the central observed-event time window to avoid a sparse tail.
event_times <- d$SURVTIME[d$SURVIND == 1]
t_min <- max(min(event_times), as.numeric(stats::quantile(event_times, 0.05)))
t_max <- as.numeric(stats::quantile(event_times, 0.95))
t_grid <- seq(t_min, t_max, length.out = 180L)
x <- cbind(1, log(t_grid))
log_hr <- drop(x %*% time_coefs)
se_log_hr <- sqrt(rowSums((x %*% time_vcov) * x))
hr_curve <- data.frame(Time = t_grid, HR = exp(log_hr),
                       CI_low = exp(log_hr - 1.96*se_log_hr),
                       CI_high = exp(log_hr + 1.96*se_log_hr))
write.csv(hr_curve, file.path(tab_dir,"time_varying_hr_curve.csv"), row.names=FALSE)

# Diagnostic summaries: they describe checks, not guarantees of validity.
psa_shapiro <- stats::shapiro.test(stats::residuals(psa_model))
psa_diag <- data.frame(Check = "Shapiro-Wilk test of PSA-model residuals",
                       Statistic = unname(psa_shapiro$statistic),
                       P_value = psa_shapiro$p.value)
write.csv(psa_diag, file.path(tab_dir,"psa_diagnostics.csv"),row.names=FALSE)

# Publication-ready base graphics, generated from the current fitted models.
colors <- c("#5576A0", "#159087")
png(file.path(fig_dir,"psa_by_treatment.png"), width=1350, height=840, res=160)
boxplot(PSA ~ arm, data=d, col=colors, border="#334155", outline=TRUE,
        ylab="PSA variable (dataset scale)", xlab="Treatment assignment",
        main="PSA distribution by randomized treatment")
mtext("Descriptive comparison, pooled across 17 trials", side=3, line=0.2, cex=0.8)
dev.off()

png(file.path(fig_dir,"kaplan_meier.png"), width=1350, height=840, res=160)
plot(km_model, col=colors, lwd=3, mark.time=TRUE,
     xlab="Follow-up time (units not specified in package documentation)",
     ylab="Estimated survival probability",
     main="Kaplan-Meier survival by treatment group", conf.int=FALSE)
legend("topright", legend=levels(d$arm), col=colors, lwd=3, bty="n")
mtext("Pooled descriptive curves; see stratified Cox analysis", side=3, line=0.1, cex=0.78)
dev.off()

png(file.path(fig_dir,"proportional_hazards_diagnostic.png"), width=1350, height=840, res=160)
plot(ph, main="Schoenfeld residual screen: treatment")
dev.off()

png(file.path(fig_dir,"time_varying_hazard_ratio.png"), width=1350, height=840, res=160)
y_range <- range(c(hr_curve$CI_low, hr_curve$CI_high, 1), finite=TRUE)
plot(hr_curve$Time, hr_curve$HR, type="n", ylim=y_range,
     xlab="Recorded follow-up time (units unspecified)",
     ylab="Experimental vs control hazard ratio",
     main="Exploratory time-varying treatment association")
polygon(c(hr_curve$Time, rev(hr_curve$Time)),
        c(hr_curve$CI_low, rev(hr_curve$CI_high)),
        col=adjustcolor(colors[1], alpha.f=0.22), border=NA)
lines(hr_curve$Time,hr_curve$HR,col=colors[1],lwd=3)
abline(h=1,lty=2,col="#B91C1C",lwd=2)
legend("topright",legend=c("Estimated HR(t)","Pointwise 95% CI","HR = 1"),
       col=c(colors[1],adjustcolor(colors[1],alpha.f=0.45),"#B91C1C"),
       lty=c(1,1,2),lwd=c(3,8,2),bty="n")
mtext("Log-time model; tail estimates excluded from plotting", side=3,line=0.1,cex=0.78)
dev.off()

png(file.path(fig_dir,"psa_regression_diagnostics.png"), width=1400, height=900, res=155)
op <- par(mfrow=c(2,2), mar=c(4,4,3,1))
plot(psa_model, which=c(1,2,3,4))
par(op)
dev.off()

# Cross-check internal quantities and fitted-model outputs before rendering.
stopifnot(sum(by_arm$Patients)==412L,
          sum(by_arm$Events)==293L,
          all(is.finite(unlist(psa_table[-1]))),
          is.finite(cox_table$HR), is.finite(ph_p),
          all(is.finite(as.matrix(hr_curve))))

# Store verified, computed numbers for report. Render reads these, not console history.
result <- list(d=d, by_arm=by_arm, psa=psa_table, km=km_table,
               cox=cox_table, ph=ph_table, time=time_table,
               hr_curve=hr_curve, psa_diag=psa_diag,
               ph_p=ph_p, time_interaction_p=time_p,
               figure_dir=fig_dir,
               session_info=capture.output(sessionInfo()),
               generated=Sys.time())
saveRDS(result, file.path(out_dir,"analysis_results.rds"))

# Report source contains prose, tables and references to pre-generated charts.
report_file <- file.path(module_dir, "prostate_report.Rmd")
if (!file.exists(report_file)) stop("Cannot find report template: ", report_file)
report_path <- file.path(out_dir, "prostate_cancer_report.html")
rmarkdown::render(input=report_file,
                  output_file="prostate_cancer_report.html",
                  output_dir=out_dir,
                  params=list(results_file=file.path(out_dir,"analysis_results.rds")),
                  quiet=TRUE, envir=new.env(parent=globalenv()))
stopifnot(file.exists(report_path))
# Keep a reviewed, shareable HTML copy outside ignored outputs/ paths.
# GitHub can store this file without changing the parent project's .gitignore.
published_dir <- file.path(module_dir, "published")
dir.create(published_dir, recursive=TRUE, showWarnings=FALSE)
if (!file.copy(report_path, file.path(published_dir, "prostate_cancer_report.html"), overwrite=TRUE)) {
  warning("Could not copy the report to published/ for GitHub.")
}
cat("\nPROSTATE CANCER ANALYSIS COMPLETED\n")
cat("Patients: ",nrow(d)," | Trials: ",length(unique(d$TRIAL))," | Events: ",sum(d$SURVIND==1),"\n",sep="")
cat("Trial-adjusted PSA difference: ",fmt(psa_table$Difference)," (",fmt_p(psa_table$P_value),")\n",sep="")
cat("Trial-stratified constant Cox HR: ",fmt(cox_table$HR)," (",fmt_p(cox_table$P_value),")\n",sep="")
cat("PH test: ",fmt_p(ph_p)," | Time interaction: ",fmt_p(time_p),"\n",sep="")
cat("HTML report: ",report_path,"\n",sep="")
cat("GitHub copy: ",file.path(published_dir, "prostate_cancer_report.html"),"\n",sep="")
cat("Figures: ",fig_dir,"\n",sep="")
cat("Tables: ",tab_dir,"\n",sep="")
