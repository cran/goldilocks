## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
load("vignette-sims.rda")

## ----one_sided_example, eval=FALSE--------------------------------------------
# out_power_1sided <- update(
#   out_power,
#   alternative = "less",
#   prob_ha = 0.975
# )

## ----setup--------------------------------------------------------------------
library(goldilocks)

## ----example_power, eval=FALSE------------------------------------------------
# hc <- prop_to_haz(0.7, endtime = 12)
# ht <- prop_to_haz(0.5, endtime = 12)
# 
# out_power <- sim_trials(
#   hazard_treatment = ht,
#   hazard_control = hc,
#   cutpoints = NULL,
#   N_total = 300,
#   lambda = 5,
#   lambda_time = NULL,
#   interim_look = seq(100, 275, 25),
#   end_of_study = 12,
#   prior_surv = c(0.1, 0.1),
#   block = 2,
#   rand_ratio = c(1, 1),
#   prop_loss = 0,
#   alternative = "two.sided",
#   Fn = rep(0.10, 8),
#   Sn = c(1, rep(0.9, 7)),
#   prob_ha = 0.95,
#   N_impute = 100,
#   N_trials = 500,
#   method = "logrank",
#   ncores = 8,
#   seed = 123)

## ----example_type1, eval=FALSE------------------------------------------------
# out_t1error <- update(out_power, hazard_treatment = hc, seed = 124)

## ----summarise_sims-----------------------------------------------------------
knitr::kable(
  summarise_sims(list(out_power$sims, out_t1error$sims)),
  digits = 3,
  caption = "Operating characteristics with a two-sided log-rank test at the 0.05 level. Scenario 1 is the alternative (treatment OS 50%); scenario 2 is the null (treatment OS 30%)."
)

## ----example_p0.04, eval=FALSE------------------------------------------------
# out_power2 <- update(out_power, prob_ha = 0.96, return_trace = TRUE)
# out_t1error2 <- update(
#   out_power2,
#   hazard_treatment = hc,
#   return_trace = FALSE,
#   seed = 125
# )

## ----summarise_sims_p0.04-----------------------------------------------------
oc_calibrated <- summarise_sims(list(
  "target: treatment OS 50%" = out_power2$sims,
  "null: treatment OS 30%" = out_t1error2$sims
))
knitr::kable(
  oc_calibrated,
  digits = 3,
  caption = "Operating characteristics with the more stringent P < 0.04 threshold (`prob_ha = 0.96`)."
)

## ----plot-ocs, fig.width=9, fig.height=4.5------------------------------------
oc_calibrated$true_treatment_survival <- c(0.50, 0.30)
plot_sim_ocs(
  oc_calibrated,
  effect = "true_treatment_survival",
  xlab = "True 12-month treatment survival probability"
)

## ----plot-stopping, fig.width=8, fig.height=5.5, out.width='100%'-------------
plot_sim_stopping(out_power2)

## ----plot-stopping-conditional, fig.width=8, fig.height=5.5, out.width='100%'----
plot_sim_stopping(out_power2, type = "conditional")

## ----plot-stopping-cumulative, fig.width=8, fig.height=5.5, out.width='100%'----
plot_sim_stopping(out_power2, type = "cumulative")

## ----plot-stopping-flowchart, fig.width=7, fig.height=12, out.width='100%'----
plot_sim_stopping(out_power2, type = "flowchart")

## ----plot-decisions, eval=FALSE-----------------------------------------------
# plot_sim_decisions(out_power2)

