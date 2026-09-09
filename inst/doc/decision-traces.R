## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
set.seed(5701)

## ----setup, message = FALSE---------------------------------------------------
library(goldilocks)

## ----traced-trial-------------------------------------------------------------
end_of_study <- 24
hazard_control <- prop_to_haz(c(0.20, 0.35), 12, end_of_study)
hazard_treatment <- prop_to_haz(c(0.12, 0.24), 12, end_of_study)

trial <- survival_adapt(
  hazard_treatment = hazard_treatment,
  hazard_control = hazard_control,
  cutpoints = 12,
  N_total = 80,
  lambda = 8,
  lambda_time = NULL,
  interim_look = c(40, 60),
  end_of_study = end_of_study,
  prior_surv = c(0.1, 0.1),
  block = 2,
  rand_ratio = c(control = 1, treatment = 1),
  prop_loss = 0.05,
  alternative = "less",
  h0 = 0,
  Fn = c(0.05, 0.05),
  Sn = c(0.95, 0.90),
  Qn = c(0.99, 0.99),
  prob_ha = 0.95,
  N_impute = 20,
  N_mcmc = 20,
  method = "bayes-surv",
  empty_interval = "prior",
  return_trace = TRUE
)

trial

## ----trace-table--------------------------------------------------------------
trial$summary
trial$trace
summarise_trial_trace(trial)

## ----enrollment-plot, fig.width = 7, fig.height = 4.8-------------------------
plot_enrollment(
  trial,
  n_sim = 20,
  seed = 20260727,
  time_unit = "months"
)

## ----trace-plot, fig.width = 7, fig.height = 8--------------------------------
plot_trial_trace(trial)

## ----simulation-summary, eval = FALSE-----------------------------------------
# sims <- sim_trials(
#   hazard_treatment = hazard_treatment,
#   hazard_control = hazard_control,
#   cutpoints = 12,
#   N_total = 80,
#   lambda = 8,
#   lambda_time = NULL,
#   interim_look = c(40, 60),
#   end_of_study = end_of_study,
#   prior_surv = c(0.1, 0.1),
#   block = 2,
#   rand_ratio = c(control = 1, treatment = 1),
#   prop_loss = 0.05,
#   alternative = "less",
#   h0 = 0,
#   Fn = c(0.05, 0.05),
#   Sn = c(0.95, 0.90),
#   Qn = c(0.99, 0.99),
#   prob_ha = 0.95,
#   N_impute = 20,
#   N_mcmc = 20,
#   N_trials = 500,
#   method = "bayes-surv",
#   return_trace = TRUE,
#   seed = 5702
# )
# 
# summarise_sims(sims)
# plot_sim_stopping(sims)
# plot_sim_stopping(sims, type = "flowchart")
# plot_sim_decisions(sims)

## ----simulation-oc-curve, eval = FALSE----------------------------------------
# scenario_oc <- summarise_sims(list(
#   "null" = sims_null,
#   "moderate" = sims_moderate,
#   "target" = sims
# ))
# effect_by_scenario <- c(null = 0, moderate = -0.05, target = -0.10)
# scenario_oc$true_event_probability_difference <- unname(
#   effect_by_scenario[scenario_oc$scenario]
# )
# 
# plot_sim_ocs(
#   scenario_oc,
#   effect = "true_event_probability_difference",
#   xlab = "True treatment-control event-probability difference"
# )

