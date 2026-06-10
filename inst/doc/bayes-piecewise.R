## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
set.seed(7194)

## ----setup, message=FALSE-----------------------------------------------------
library(goldilocks)

## ----hazards------------------------------------------------------------------
cutpoints <- c(0, 6)         # one internal cut at 6 months -> two intervals
end_of_study <- 24

hc <- prop_to_haz(probs = c(0.30, 0.50), cutpoints = cutpoints, endtime = end_of_study)
ht <- prop_to_haz(probs = c(0.18, 0.40), cutpoints = cutpoints, endtime = end_of_study)

round(rbind(control = hc, treatment = ht), 4)

## ----check_cif----------------------------------------------------------------
ppwe(hazard       = matrix(hc, nrow = 1),
     cutpoints    = cutpoints,
     end_of_study = end_of_study)
ppwe(hazard       = matrix(ht, nrow = 1),
     cutpoints    = cutpoints,
     end_of_study = end_of_study)

## ----prior--------------------------------------------------------------------
prior <- c(0.1, 0.1)   # shape and rate of the Gamma prior on each lambda_j

## ----run_one_trial, cache=TRUE------------------------------------------------
out <- survival_adapt(
  hazard_treatment = ht,
  hazard_control   = hc,
  cutpoints        = cutpoints,
  N_total          = 100,
  lambda           = 5,                # enrolments per month
  lambda_time      = 0,                # constant accrual rate
  interim_look     = 60,
  end_of_study     = end_of_study,
  prior            = prior,
  block            = 4,
  rand_ratio       = c(1, 1),
  prop_loss        = 0.05,
  alternative      = "less",
  h0               = 0,
  Fn               = 0.05,
  Sn               = 0.95,
  prob_ha          = 0.975,
  N_impute         = 50,
  N_mcmc           = 2000,
  method           = "bayes")

out

## ----flat_design, eval=FALSE--------------------------------------------------
# hc_flat <- prop_to_haz(0.50, endtime = end_of_study)   # control, single hazard
# ht_flat <- prop_to_haz(0.40, endtime = end_of_study)   # treatment, single hazard
# 
# out_flat <- survival_adapt(
#   hazard_treatment = ht_flat,
#   hazard_control   = hc_flat,
#   cutpoints        = 0,
#   N_total          = 100,
#   lambda           = 5,
#   lambda_time      = 0,
#   interim_look     = 60,
#   end_of_study     = end_of_study,
#   prior            = prior,
#   block            = 4,
#   rand_ratio       = c(1, 1),
#   prop_loss        = 0.05,
#   alternative      = "less",
#   h0               = 0,
#   Fn               = 0.05,
#   Sn               = 0.95,
#   prob_ha          = 0.975,
#   N_impute         = 50,
#   N_mcmc           = 2000,
#   method           = "bayes")

