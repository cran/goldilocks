## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
set.seed(3081)

## ----setup, message=FALSE-----------------------------------------------------
library(goldilocks)

## ----design-------------------------------------------------------------------
end_of_study <- 24
benchmark <- 0.30                       # external standard-of-care failure rate
target    <- 0.20                       # rate we hope the new therapy achieves

# Convert the target failure rate into a constant hazard (so we can simulate)
ht <- prop_to_haz(probs = target, endtime = end_of_study)
ht

## ----run, cache=TRUE----------------------------------------------------------
out <- survival_adapt(
  hazard_treatment = ht,
  hazard_control   = NULL,              # single-arm
  cutpoints        = 0,
  N_total          = 80,
  lambda           = 5,                 # enrolments per month (constant)
  lambda_time      = 0,
  interim_look     = 50,
  end_of_study     = end_of_study,
  prior            = c(0.1, 0.1),       # Gamma(0.1, 0.1) on the hazard
  block            = 2,                 # default; inert in single-arm mode
  rand_ratio       = c(1, 1),           # default; inert in single-arm mode
  prop_loss        = 0.05,
  alternative      = "less",
  h0               = benchmark,         # benchmark failure probability
  Fn               = 0.05,
  Sn               = 0.95,
  prob_ha          = 0.95,
  N_impute         = 50,
  N_mcmc           = 2000,
  method           = "bayes")

out

## ----oc, eval=FALSE-----------------------------------------------------------
# # Power: simulate under the alternative (true rate = 0.20)
# out_power <- sim_trials(
#   N_trials         = 1000,
#   hazard_treatment = ht,
#   hazard_control   = NULL,
#   cutpoints        = 0,
#   N_total          = 80,
#   lambda           = 5,
#   lambda_time      = 0,
#   interim_look     = 50,
#   end_of_study     = end_of_study,
#   prior            = c(0.1, 0.1),
#   block            = 2,
#   rand_ratio       = c(1, 1),
#   prop_loss        = 0.05,
#   alternative      = "less",
#   h0               = benchmark,
#   Fn               = 0.05,
#   Sn               = 0.95,
#   prob_ha          = 0.95,
#   N_impute         = 50,
#   N_mcmc           = 2000,
#   method           = "bayes")
# 
# # Type I error: simulate under the null (true rate = benchmark = 0.30)
# ht_null <- prop_to_haz(probs = benchmark, endtime = end_of_study)
# out_t1error <- sim_trials(
#   N_trials         = 1000,
#   hazard_treatment = ht_null,
#   hazard_control   = NULL,
#   cutpoints        = 0,
#   N_total          = 80,
#   lambda           = 5,
#   lambda_time      = 0,
#   interim_look     = 50,
#   end_of_study     = end_of_study,
#   prior            = c(0.1, 0.1),
#   block            = 2,
#   rand_ratio       = c(1, 1),
#   prop_loss        = 0.05,
#   alternative      = "less",
#   h0               = benchmark,
#   Fn               = 0.05,
#   Sn               = 0.95,
#   prob_ha          = 0.95,
#   N_impute         = 50,
#   N_mcmc           = 2000,
#   method           = "bayes")
# 
# summarise_sims(list(out_power$sims, out_t1error$sims))

