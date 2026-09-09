## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(goldilocks)

## -----------------------------------------------------------------------------
set.seed(1410)
trial <- survival_adapt(
  hazard_control = c(0.10, 0.10),
  hazard_treatment = c(0.10, 0.04),
  cutpoints = 3,
  N_total = 160,
  lambda = 8,
  interim_look = c(80, 120),
  end_of_study = 12,
  method = "rmst",
  rmst_tau = 9,
  alternative = "greater",
  h0 = 0,
  prob_ha = 0.975,
  N_impute = 100,
  return_trace = TRUE
)
trial$summary[, c("est_final", "post_prob_ha", "N_enrolled", "trial_success")]
trial$trace[, c("planned_N", "ppp_stop_now", "decision")]

## -----------------------------------------------------------------------------
sims <- sim_trials(
  hazard_control = 0.10,
  hazard_treatment = 0.10,
  N_total = 160,
  lambda = 8,
  interim_look = 80,
  end_of_study = 12,
  method = "rmst",
  rmst_tau = 9,
  alternative = "greater",
  prob_ha = 0.975,
  N_impute = 50,
  N_trials = 20,
  backend = "sequential",
  seed = 1411
)
summarise_sims(sims)
sims$failures

