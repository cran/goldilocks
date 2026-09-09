## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
set.seed(5107)

## ----setup, message=FALSE-----------------------------------------------------
library(goldilocks)

## ----priors-------------------------------------------------------------------
hazard_prior <- c(0.1, 0.1)  # Gamma shape and rate for predictive imputation
prior_bin <- c(1, 1)         # Beta shapes for the binary endpoint analysis

## ----two_arm_design-----------------------------------------------------------
end_of_study <- 12
hc <- prop_to_haz(0.35, endtime = end_of_study)
ht <- prop_to_haz(0.25, endtime = end_of_study)

two_arm_args <- list(
  hazard_treatment = ht,
  hazard_control = hc,
  cutpoints = NULL,
  N_total = 120,
  lambda = 10,
  lambda_time = NULL,
  interim_look = 80,
  end_of_study = end_of_study,
  prior_surv = hazard_prior,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  block = 2,
  rand_ratio = c(control = 1, treatment = 1),
  prop_loss = 0,
  alternative = "less",
  h0 = 0,
  Fn = 0.05,
  Sn = 0.90,
  prob_ha = 0.95,
  N_impute = 20,
  method = "bayes-bin",
  imputed_final = FALSE
)

out_two_arm <- do.call(survival_adapt, two_arm_args)
out_two_arm

## ----compare_binary_imputation------------------------------------------------
compare_binary_imputation <- function(imputation) {
  set.seed(2101)
  fit <- do.call(
    survival_adapt,
    c(two_arm_args, list(binary_imputation = imputation))
  )
  fit[c("ppp_success", "post_prob_ha", "est_final")]
}

rbind(
  `conditional event time` = compare_binary_imputation("event-time"),
  `direct Bernoulli status` = compare_binary_imputation("bernoulli")
)

## ----single_arm_design--------------------------------------------------------
benchmark <- 0.30
target <- 0.20
ht_single <- prop_to_haz(target, endtime = end_of_study)

out_single_arm <- survival_adapt(
  hazard_treatment = ht_single,
  hazard_control = NULL,
  cutpoints = NULL,
  N_total = 80,
  lambda = 8,
  lambda_time = NULL,
  interim_look = 50,
  end_of_study = end_of_study,
  prior_surv = hazard_prior,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  prop_loss = 0,
  alternative = "less",
  h0 = benchmark,
  Fn = 0.05,
  Sn = 0.90,
  prob_ha = 0.95,
  N_impute = 20,
  method = "bayes-bin",
  imputed_final = FALSE
)

out_single_arm

## ----oc, eval=FALSE-----------------------------------------------------------
# out_power <- sim_trials(
#   N_trials = 1000,
#   hazard_treatment = ht,
#   hazard_control = hc,
#   cutpoints = NULL,
#   N_total = 120,
#   lambda = 10,
#   lambda_time = NULL,
#   interim_look = 80,
#   end_of_study = end_of_study,
#   prior_surv = hazard_prior,
#   prior_bin = prior_bin,
#   bin_method = "quadrature",
#   block = 2,
#   rand_ratio = c(control = 1, treatment = 1),
#   prop_loss = 0,
#   alternative = "less",
#   h0 = 0,
#   Fn = 0.05,
#   Sn = 0.90,
#   prob_ha = 0.95,
#   N_impute = 20,
#   method = "bayes-bin",
#   imputed_final = FALSE,
#   return_trace = TRUE,
#   ncores = 2,
#   seed = 5107
# )
# 
# out_null <- update(out_power, hazard_treatment = hc, seed = 5108)
# 
# oc <- summarise_sims(list(
#   "target: treatment event probability 25%" = out_power,
#   "null: treatment event probability 35%" = out_null
# ))
# effect_by_scenario <- c(
#   "target: treatment event probability 25%" = 0.25,
#   "null: treatment event probability 35%" = 0.35
# )
# oc$true_treatment_event_probability <- unname(effect_by_scenario[oc$scenario])
# 
# oc
# plot_sim_ocs(
#   oc,
#   effect = "true_treatment_event_probability",
#   xlab = "True treatment event probability"
# )
# plot_sim_stopping(out_power)
# plot_sim_decisions(out_power)

