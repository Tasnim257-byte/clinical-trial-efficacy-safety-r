# Synthetic trial data dictionary

**Source:** Fully fictional observations generated for a portfolio demonstration. Not from an actual clinical trial.

| Column | Type | Definition |
|---|---|---|
| `participant_id` | string | Unique fictional participant identifier (`P0001`...) |
| `site` | string | Simulated site label, from `Site_01` to `Site_06` |
| `arm` | categorical | Randomized group, `Control` or `Treatment` |
| `age` | integer | Simulated age in years (18–85) |
| `sex` | categorical | Simulated `Female`/`Male` category, for exercise only |
| `baseline_score` | decimal | Symptom burden at baseline, 0–100, higher = worse |
| `week12_score` | decimal or NA | Symptom burden at week 12, 0–100, higher = worse |
| `responder` | 0/1 or NA | `1` if baseline minus week-12 score is at least 12; NA if outcome missing |
| `ae_headache` | 0/1 | At least one simulated headache AE |
| `ae_nausea` | 0/1 | At least one simulated nausea AE |
| `ae_fatigue` | 0/1 | At least one simulated fatigue AE |
| `ae_rash` | 0/1 | At least one simulated rash AE |
| `any_ae` | 0/1 | Any of the four listed event types present |
| `serious_ae` | 0/1 | Simulated SAE flag; constructed as a subset of any AE |

Each row is one randomized participant. Safety variables are simulated as fully observed over a common follow-up window. There are no actual dates, medications, diagnoses, sites, or patients. `NA` in the outcome fields means not observed, not a zero score.

## Synthetic data design

- Exactly 300 participants are allocated to each arm in the bundled sample.
- Baseline score is roughly normally distributed with a mean near 65 and SD near 11.
- Treatment reduces the week-12 symptom score in the generating mechanism, but individual outcomes vary.
- Follow-up values are sometimes missing by a probability depending partly on baseline score and assignment.
- Event flags are drawn from different simulated Bernoulli probabilities by arm.
- Data do not represent an approved medicine, medical device, intervention, or actual trial.
