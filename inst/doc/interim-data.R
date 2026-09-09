## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## ----setup, message = FALSE---------------------------------------------------
library(goldilocks)

## ----blinded-data-------------------------------------------------------------
blinded_cut <- data.frame(
  id = 1:8,
  enrollment = 0:7,
  time = c(8, 7, 6, 5, 4, 3, 2, 1),
  event = c(1, 0, 0, 1, 0, 0, 0, 0),
  status = c(
    "event", "pending", "censored", "event",
    "pending", "pending", "pending", "pending"
  )
)

blinded_cut

## ----unblinded-data-----------------------------------------------------------
randomization_export <- data.frame(
  id = 1:8,
  treatment = c(0, 1, 0, 1, 0, 1, 0, 1)
)

interim_cut <- blinded_cut
interim_cut$treatment <- randomization_export$treatment[
  match(interim_cut$id, randomization_export$id)
]
interim_cut <- interim_cut[
  c("id", "treatment", "enrollment", "time", "event", "status")
]

## ----evaluate-look------------------------------------------------------------
interim_result <- evaluate_interim(
  data = interim_cut,
  data_cut = 8,
  look = 2,
  N_total = 12,
  end_of_study = 10,
  rand_ratio = c(control = 1, treatment = 1),
  method = "logrank",
  alternative = "less",
  Fn = 0.05,
  Sn = 0.90,
  Qn = 1,
  prob_ha = 0.95,
  N_impute = 20,
  seed = 20260831
)

interim_result
interim_result$decision
interim_result$monte_carlo

## ----allocation-diagnostics---------------------------------------------------
interim_result$diagnostics$target_allocation
interim_result$diagnostics$current_allocation
interim_result$diagnostics$potential_accruals

## ----separate-prior-look------------------------------------------------------
predictive_prior <- list(
  control = c(shape = 10, rate = 200),
  treatment = c(shape = 6, rate = 200)
)
analysis_prior <- c(shape = 0.1, rate = 0.1)

bayes_prior_result <- evaluate_interim(
  data = interim_cut,
  data_cut = 8,
  look = 2,
  N_total = 12,
  end_of_study = 10,
  method = "bayes-surv",
  alternative = "less",
  h0 = 0,
  prior_surv = predictive_prior,    # Generates outstanding outcomes
  prior_surv_final = analysis_prior, # Tests each hypothetical completed trial
  Fn = 0.05,
  Sn = 0.90,
  Qn = 1,
  prob_ha = 0.975,
  N_impute = 100,
  N_mcmc = 1000,
  seed = 20260909
)

knitr::kable(
  bayes_prior_result$diagnostics$prior[
    c("stage", "arm", "shape", "rate", "mean_hazard")
  ],
  digits = 3,
  caption = "Gamma priors used in the two parts of this interim calculation."
)
bayes_prior_result$probabilities

## ----evaluate-rmst-look-------------------------------------------------------
rmst_result <- evaluate_interim(
  data = interim_cut,
  data_cut = 8,
  look = 2,
  N_total = 12,
  end_of_study = 10,
  rand_ratio = c(control = 1, treatment = 1),
  method = "rmst",
  rmst_tau = 6,
  alternative = "greater",
  h0 = 0,
  Fn = 0.05,
  Sn = 0.90,
  Qn = 1,
  prob_ha = 0.95,
  N_impute = 20,
  seed = 20260908
)

rmst_result$decision
rmst_result$monte_carlo
rmst_result$metadata$design[c("method", "rmst_tau", "alternative", "h0")]

## ----audit-trace--------------------------------------------------------------
summarise_trial_trace(interim_result)
interim_result$trace

