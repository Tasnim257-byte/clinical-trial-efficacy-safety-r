# Analysis plan — educational example

## 1. Purpose and design

Estimate the simulated treatment difference in a fictional 12-week 1:1 randomized parallel-group experiment. There are six fictional study sites. The objective is to practice reproducible R workflows, not to produce clinical evidence.

## 2. Analysis populations

- **Randomized set:** All 600 randomized simulated participants.
- **Observed-outcome efficacy set:** Participants with a recorded baseline and week-12 score. No attempt is made to characterize missingness as ignorable; the analysis is illustrative.
- **Safety denominator:** The full randomized set. A real safety population is typically based on actual exposure; no treatment exposure records exist in this example.

## 3. Outcomes

- **Continuous efficacy:** Week-12 symptom burden score on a 0–100 scale, where lower values are better. Covariate-adjusted treatment difference is Treatment minus Control.
- **Responder:** Improvement ≥12 points from baseline at week 12; secondary/exploratory.
- **Safety:** At least one simulated adverse event, serious event flag, and four named event categories.

## 4. Models and inference

- Fit ordinary least-squares ANCOVA with randomized arm, baseline score, age, sex and site as explanatory variables.
- Present coefficient of `armTreatment`, 95% t-based interval and two-sided p-value.
- Use logistic regression for the responder outcome; present exponentiated treatment coefficient and approximate 95% Wald confidence interval.
- Summarize binary adverse events by treatment arm with event counts, rates, and Wilson score 95% intervals. For the "any AE" row also report crude risk difference, crude risk ratio, and Fisher exact p-value.
- No confirmatory multiplicity adjustment is applied. All inferential quantities are *exploratory*.

## 5. Missing data

- Primary demonstration uses observed outcomes only. This may be biased if dropouts depend on outcomes conditional on modeled covariates.
- Simple BOCF sensitivity imputes missing week-12 scores with baseline, corresponding to no improvement. This is pedagogical and can introduce bias or unrealistic assumptions.
- A more defensible follow-on would use multiple imputation under explicit assumptions and a pattern-mixture sensitivity analysis.

## 6. Simulation

Each Monte Carlo repetition samples a simplified baseline measure and follow-up outcome, with configurable treatment effect, residual noise and equal arm sizes. ANCOVA rejections are counted at a two-sided 0.05 significance level. Estimated rejection rates come with Monte Carlo standard errors, not confidence intervals for real clinical effects. The simulated model differs deliberately from the example CSV generator to illustrate model-assumption sensitivity.

## 7. Validation and reproducibility

- Validate IDs, factor values, outcome ranges, missingness consistency, response calculation and adverse event flags.
- All scripts depend only on base R; report rendering uses optional R Markdown.
- Data generator and Monte Carlo use explicit seeds.
- Running from the project root is a requirement; no external file paths or credentials are used.

## 8. Explicit limitations

This demonstration lacks exposure measurement, longitudinal visits, real adverse-event reporting standards, protocol deviations, competing events, robust missing data mechanisms, prospective estimands, multiplicity corrections and real-world covariate structure. It is not regulatory-grade or clinically interpretable.
