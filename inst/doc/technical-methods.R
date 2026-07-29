## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE---------------------------------------------------------------
# out <- sim_trials(
#   hazard_treatment = ht,
#   hazard_control   = hc,
#   cutpoints        = cutpoints,
#   N_total          = N_total,
#   lambda           = lambda,
#   lambda_time      = lambda_time,
#   interim_look     = interim_look,
#   end_of_study     = end_of_study,
#   prior_surv       = prior_surv,
#   Fn               = Fn,
#   Sn               = Sn,
#   prob_ha          = prob_ha,
#   N_impute         = N_impute,
#   N_mcmc           = N_mcmc,
#   N_trials         = N_trials,
#   method           = method,
#   seed             = 12345)
# 
# summarise_sims(out$sims)

## ----eval=FALSE---------------------------------------------------------------
# scenario_oc <- summarise_sims(list(
#   "null" = null_sims$sims,
#   "moderate" = moderate_sims$sims,
#   "target" = target_sims$sims
# ))
# scenario_oc$true_effect <- c(0, -0.10, -0.20)
# 
# plot_sim_ocs(
#   scenario_oc,
#   effect = "true_effect",
#   xlab = "True treatment-control event-probability difference"
# )
# plot_sim_stopping(target_sims)

## ----eval=FALSE---------------------------------------------------------------
# target_sims_traced <- update(target_sims, return_trace = TRUE)
# plot_sim_stopping(target_sims_traced, type = "flowchart")
# plot_sim_decisions(target_sims_traced)

