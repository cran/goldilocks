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
#   Qn               = Qn,
#   prob_ha          = prob_ha,
#   N_impute         = N_impute,
#   N_mcmc           = N_mcmc,
#   N_trials         = N_trials,
#   method           = method,
#   seed             = 12345)
# 
# summarise_sims(
#   out,
#   max_mcse = c(power = 0.005, stop_futility = 0.01, mean_N = 1)
# )

## ----eval=FALSE---------------------------------------------------------------
# scenario_oc <- summarise_sims(list(
#   "null" = null_sims,
#   "moderate" = moderate_sims,
#   "target" = target_sims
# ))
# effect_by_scenario <- c(null = 0, moderate = -0.10, target = -0.20)
# scenario_oc$true_effect <- unname(effect_by_scenario[scenario_oc$scenario])
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

