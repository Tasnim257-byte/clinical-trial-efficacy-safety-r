# Publication-style base R figures, written as PNGs (no ggplot2 needed).

make_trial_plots <- function(trial, efficacy, safety) {
  dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
  arm <- factor(as.character(trial$arm), levels = c("Control", "Treatment"))
  arm_colors <- c(Control = "#456D94", Treatment = "#1C9A8A")

  png("outputs/figures/baseline_balance.png", width = 1200, height = 750, res = 150)
  boxplot(trial$baseline_score ~ arm, col = unname(arm_colors), border = "#23313f",
          main = "Baseline symptom score by randomized arm",
          xlab = "Randomized arm", ylab = "Baseline score (0–100; higher = worse)")
  grid(nx = NA, ny = NULL, col = "#DDE4EA")
  dev.off()

  png("outputs/figures/efficacy_change.png", width = 1200, height = 750, res = 150)
  observed <- !is.na(trial$week12_score)
  changes <- trial$week12_score[observed] - trial$baseline_score[observed]
  boxplot(changes ~ droplevels(arm[observed]), col = unname(arm_colors),
          border = "#23313f", main = "Change in symptom score at week 12",
          xlab = "Randomized arm", ylab = "Week 12 − baseline (negative = improvement)")
  abline(h = 0, lty = 2, col = "#8A929B")
  dev.off()

  png("outputs/figures/safety_incidence.png", width = 1300, height = 800, res = 150)
  events <- safety$event_table
  names_in_order <- unique(events$event)
  trt <- events[events$arm == "Treatment", , drop = FALSE]
  ctl <- events[events$arm == "Control", , drop = FALSE]
  # Row sequence matches the ordered list of endpoints by construction.
  mat <- rbind(Control = ctl$risk * 100, Treatment = trt$risk * 100)
  colnames(mat) <- names_in_order
  bp <- barplot(mat, beside = TRUE, col = unname(arm_colors),
                las = 2, ylim = c(0, max(mat) * 1.25 + 2),
                ylab = "Participants with event (%)",
                main = "Treatment-emergent adverse events (synthetic data)",
                cex.names = 0.85)
  legend("topright", legend = rownames(mat), fill = unname(arm_colors), bty = "n")
  dev.off()

  invisible(c("baseline_balance.png", "efficacy_change.png", "safety_incidence.png"))
}

if (sys.nframe() == 0L) {
  source("R/helpers.R")
  source("R/analyze_efficacy.R")
  source("R/analyze_safety.R")
  trial <- read_trial()
  make_trial_plots(trial, analyze_efficacy(trial), analyze_safety(trial))
  cat("PNG files written to outputs/figures.\n")
}
