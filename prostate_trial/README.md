# Real prostate cancer randomized trials: R reproducible report

This folder is a **separate real-data analysis module** for the existing `clinical-trial-efficacy-safety-r` portfolio repository. It does not change or replace the original synthetic clinical trial analysis.

## One command

Open `ClinicalTrialAnalysis.Rproj` in RStudio and run:

```r
source("real_data/prostate_trial/run_prostate_report.R")
```

If needed, install packages once:

```r
install.packages(c("Surrogate", "survival", "rmarkdown", "knitr"))
```

The command loads `Surrogate::prostate`, checks its structure, performs a trial-adjusted PSA regression and two survival models, checks assumptions, draws charts, saves CSV tables, and renders a self-contained HTML report.

### Output

- `outputs/prostate_cancer_report.html`: primary research report
- `outputs/figures/`: PSA boxplot, Kaplan-Meier, Cox PH diagnostic, PSA regression diagnostics, time-varying HR with pointwise 95% CI
- `outputs/tables/`: data summaries, PSA regression, Cox HRs, diagnostics and the HR(t) curve
- `outputs/analysis_results.rds`: analysis bundle for reproducible reporting
- `published/prostate_cancer_report.html`: shareable self-contained report copy that can be committed to GitHub

If RStudio says `pandoc not found`, run from RStudio rather than a standalone command-line R installation, or install Pandoc.

## Research cautions

The dataset is historical real patient data, unlike the synthetic main project. There are 412 records across 17 randomized trials. PSA measurement scale, exact time units, and treatment regimens are not specified in the R package's brief dataset description. No adverse-event data are included. Do not treat the numerical regression findings as a claim of clinical efficacy, safety, or proven PSA surrogacy.

Dataset documentation: https://search.r-project.org/CRAN/refmans/Surrogate/html/prostate.html
