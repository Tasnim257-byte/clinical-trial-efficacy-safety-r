# Complete reproducible pipeline. Run from repository root: Rscript run_all.R
source("R/helpers.R")
source("R/analyze_efficacy.R")
source("R/analyze_safety.R")
source("R/power_simulation.R")
source("R/plots.R")

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
trial <- read_trial()
efficacy <- analyze_efficacy(trial)
safety <- analyze_safety(trial)
operating_characteristics <- run_power_scenarios()

write_table(efficacy$primary, "efficacy_primary.csv")
write_table(efficacy$sensitivity, "efficacy_sensitivity.csv")
write_table(efficacy$responder, "efficacy_responder.csv")
write_table(efficacy$arm_summary, "efficacy_arm_summary.csv")
write_table(safety$event_table, "safety_events.csv")
write_table(safety$primary_safety, "safety_comparison.csv")
write_table(operating_characteristics, "simulation_operating_characteristics.csv")
writeLines(capture.output(summary(efficacy$primary_model)), "outputs/tables/efficacy_model.txt")
make_trial_plots(trial, efficacy, safety)

cat("\nAnalysis finished: outputs/tables and outputs/figures.\n")
print(efficacy$primary)
print(safety$primary_safety)

# Optional rendered report, which requires rmarkdown, knitr and Pandoc.
if (requireNamespace("rmarkdown", quietly = TRUE) &&
    requireNamespace("knitr", quietly = TRUE) &&
    rmarkdown::pandoc_available()) {
  rmarkdown::render("reports/clinical_trial_report.Rmd", output_file = "clinical_trial_report.html",
                    output_dir = normalizePath("outputs"), quiet = TRUE)
  cat("Rendered outputs/clinical_trial_report.html\n")
} else {
  cat("Optional HTML report skipped (install rmarkdown/knitr and Pandoc).\n")
}
