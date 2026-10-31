# How to describe this project in an interview

**One-sentence summary:** "I'm building a reproducible R workflow on synthetic randomized-trial data to practice estimating treatment effects, examining adverse-event rates, handling missing observations, and assessing statistical power through simulation."

## Why did you use simulated data?

"I wanted to build and test the end-to-end pipeline without exposing private patient records or making unsupported claims about a real treatment. All participants and outcomes are fictional. I plan to extend the project to suitably licensed public clinical-trial data."

## Why ANCOVA instead of comparing raw week-12 scores?

"Adjusting for baseline symptom burden generally improves precision when baseline strongly predicts the outcome. I also adjusted for age, sex and site as planned covariates in the example. The primary coefficient is the estimated Treatment-minus-Control difference at week 12."

## Why include a missing-data sensitivity analysis?

"A complete-case analysis can be biased when follow-up is incomplete. I included baseline observation carried forward as a simple contrast to show how assumptions change results, but it is not a robust solution. Multiple imputation and pattern-mixture models would be stronger next steps."

## What is the difference between efficacy and safety endpoints?

"Efficacy considers improvement on the symptom score or responder endpoint. Safety describes the proportion of participants reporting adverse events. A numerical safety difference does not prove a real treatment is harmful, especially in a fictional, small, short follow-up design."

## What does the simulation do?

"It repeatedly generates datasets under chosen effect sizes and fits the same basic ANCOVA structure. It estimates how often we would reject a null hypothesis under those assumed settings, along with simulation uncertainty."

## Suggested resume bullet (only after the pipeline is run and reviewed)

- Developed a reproducible R pipeline using synthetic randomized-trial data to assess efficacy with ANCOVA and logistic regression, summarize adverse-event incidence, and evaluate statistical operating characteristics through Monte Carlo simulation.

If you have not run and understood the code yet, describe it as an **ongoing project** rather than as a completed analysis.
