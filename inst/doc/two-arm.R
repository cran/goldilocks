## ----include = FALSE----------------------------------------------------------
source("shared-vignette-resources.R")
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
#   rand_ratio = c(control = 1, treatment = 1),
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
initial_oc <- summarise_sims(list(out_power, out_t1error))
knitr::kable(
  initial_oc[c(
    "scenario",
    "n_requested",
    "n_used",
    "n_failed",
    "power",
    "stop_success",
    "stop_futility",
    "stop_max_N",
    "mean_N"
  )],
  digits = 3,
  col.names = c(
    "Scenario", "Requested", "Used", "Failed runs", "Power",
    "Expected success stop", "Futility stop", "Maximum N", "Mean N"
  ),
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
  "target: treatment OS 50%" = out_power2,
  "null: treatment OS 30%" = out_t1error2
), max_mcse = c(power = 0.02, mean_N = 3))

target_oc <- oc_calibrated[
  oc_calibrated$scenario == "target: treatment OS 50%",
]
null_oc <- oc_calibrated[
  oc_calibrated$scenario == "null: treatment OS 30%",
]

format_mc_interval <- function(estimate, lower, upper, digits = 3) {
  format_string <- paste0(
    "%.", digits, "f [%.", digits, "f-%.", digits, "f]"
  )
  sprintf(format_string, estimate, lower, upper)
}
oc_calibrated_display <- data.frame(
  scenario = oc_calibrated$scenario,
  simulations = sprintf(
    "%d/%d (%d)",
    oc_calibrated$n_used,
    oc_calibrated$n_requested,
    oc_calibrated$n_failed
  ),
  power = format_mc_interval(
    oc_calibrated$power,
    oc_calibrated$power_mc_lower,
    oc_calibrated$power_mc_upper
  ),
  expected_success = format_mc_interval(
    oc_calibrated$stop_success,
    oc_calibrated$stop_success_mc_lower,
    oc_calibrated$stop_success_mc_upper
  ),
  futility = format_mc_interval(
    oc_calibrated$stop_futility,
    oc_calibrated$stop_futility_mc_lower,
    oc_calibrated$stop_futility_mc_upper
  ),
  maximum_N = format_mc_interval(
    oc_calibrated$stop_max_N,
    oc_calibrated$stop_max_N_mc_lower,
    oc_calibrated$stop_max_N_mc_upper
  ),
  mean_N = format_mc_interval(
    oc_calibrated$mean_N,
    oc_calibrated$mean_N_mc_lower,
    oc_calibrated$mean_N_mc_upper,
    digits = 1
  )
)
knitr::kable(
  oc_calibrated_display,
  col.names = c(
    "Scenario",
    "Used/requested (failed)",
    "Power [95% MC CI]",
    "Expected success [95% MC CI]",
    "Futility [95% MC CI]",
    "Maximum N [95% MC CI]",
    "Mean N [95% MC CI]"
  ),
  caption = "Operating characteristics with the more stringent P < 0.04 threshold (`prob_ha = 0.96`)."
)

## ----calendar-duration--------------------------------------------------------
calendar_oc <- summarise_calendar_time(out_power2)
calendar_duration <- calendar_oc$trial_duration
calendar_duration$trials <- sprintf(
  "%d (%.1f%%)",
  calendar_duration$n_trials,
  calendar_duration$percent_trials
)
calendar_duration$accrual <- sprintf(
  "%.1f [%.1f-%.1f]",
  calendar_duration$accrual_stop_median,
  calendar_duration$accrual_stop_p10,
  calendar_duration$accrual_stop_p90
)
calendar_duration$analysis_ready <- sprintf(
  "%.1f [%.1f-%.1f]",
  calendar_duration$analysis_ready_median,
  calendar_duration$analysis_ready_p10,
  calendar_duration$analysis_ready_p90
)
knitr::kable(
  calendar_duration[c(
    "stopping_reason",
    "trials",
    "mean_N",
    "accrual",
    "analysis_ready",
    "followup_person_time_mean",
    "peak_active_followup_mean"
  )],
  digits = 1,
  col.names = c(
    "Stopping reason",
    "Trials, n (%)",
    "Mean enrolled",
    "Accrual stopped, median [P10-P90]",
    "Analysis ready, median [P10-P90]",
    "Mean person-months",
    "Mean peak under follow-up"
  ),
  caption = "Calendar-time duration and follow-up burden under the treatment-effect scenario."
)

## ----calendar-interims--------------------------------------------------------
calendar_interim <- calendar_oc$interim_timing
calendar_interim$reached <- sprintf(
  "%d (%.1f%%)",
  calendar_interim$n_reached,
  calendar_interim$percent_reached
)
calendar_interim$calendar_time <- sprintf(
  "%.1f [%.1f-%.1f]",
  calendar_interim$calendar_time_median,
  calendar_interim$calendar_time_p10,
  calendar_interim$calendar_time_p90
)
calendar_interim$active_followup <- sprintf(
  "%.0f [%.0f-%.0f]",
  calendar_interim$active_followup_median,
  calendar_interim$active_followup_p10,
  calendar_interim$active_followup_p90
)
knitr::kable(
  calendar_interim[c(
    "look",
    "planned_N",
    "reached",
    "calendar_time",
    "active_followup"
  )],
  col.names = c(
    "Look",
    "Planned N",
    "Reached, n (%)",
    "Calendar month, median [P10-P90]",
    "Active follow-up, median [P10-P90]"
  ),
  caption = "Calendar timing and concurrent follow-up at each interim look."
)

## ----plot-ocs, fig.width=9, fig.height=4.5------------------------------------
effect_by_scenario <- c(
  "target: treatment OS 50%" = 0.50,
  "null: treatment OS 30%" = 0.30
)
oc_calibrated$true_treatment_survival <- unname(
  effect_by_scenario[oc_calibrated$scenario]
)
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

