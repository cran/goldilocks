## ----include = FALSE----------------------------------------------------------
source("shared-vignette-resources.R")
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 4.8
)
set.seed(3425422)

## ----setup, message = FALSE---------------------------------------------------
library(goldilocks)

## ----reported-flow, echo = FALSE, message = FALSE, out.width = "100%"---------
DiagrammeR::grViz("
digraph anthem_flow {
  graph [rankdir = TB, bgcolor = transparent, ranksep = 0.45, nodesep = 0.30]
  node [shape = box, style = rounded, fontname = Helvetica, fontsize = 13,
        margin = 0.10]
  edge [fontname = Helvetica, fontsize = 11]

  start [label = 'Interim update\nN = 400*, 500, ..., 1000']
  fut [shape = diamond, label = 'PPSmax < 0.01?']
  stopf [label = 'Stop for futility']
  eligible [shape = diamond, label = 'N = 500, ..., 900?']
  succ [shape = diamond, label = 'PPSn > 0.95?']
  stops [label = 'Stop enrollment\nfor expected success']
  more [shape = diamond, label = 'N < 1000?']
  accrue [label = 'Continue enrollment\nto next 100-patient look']
  follow [label = 'Continue follow-up to\ncommon final study visit']
  final [label = 'One-sided log-rank test\nsuccess if P <= 0.019']

  start -> fut
  fut -> stopf [label = 'Yes']
  fut -> eligible [label = 'No']
  eligible -> succ [label = 'Yes']
  eligible -> more [label = 'No']
  succ -> stops [label = 'Yes']
  succ -> more [label = 'No']
  more -> accrue [label = 'Yes']
  accrue -> start
  more -> follow [label = 'No']
  stopf -> follow
  stops -> follow
  follow -> final
}
", width = "100%", height = "760px")

## ----input-audit, echo = FALSE------------------------------------------------
input_audit <- data.frame(
  Input = c(
    "`N_total`",
    "`interim_look`",
    "`end_of_study`",
    "`rand_ratio`",
    "`block`",
    "`lambda`, `lambda_time`",
    "`cutpoints`",
    "`generation_cutpoints`",
    "`hazard_control`",
    "`hazard_treatment`",
    "`prop_loss`",
    "`prior_surv`",
    "`alternative`",
    "`h0`",
    "`Fn`",
    "`Sn`",
    "`prob_ha`",
    "`method`",
    "`imputed_final`",
    "`N_impute`",
    "`N_trials`"
  ),
  Value = c(
    "1000",
    "400, 500, 600, 700, 800, 900",
    "16 months (69.33 weeks)",
    "1 control : 2 treatment",
    "3",
    "Six-step ramp to 26 patients/month",
    "6 and 12 months",
    "12 months",
    "0.00828, 0.00240 events/week",
    "0.70 x control hazard",
    "0.10",
    "Gamma shapes 1; rates 1/0.0069, 1/0.0069, 1/0.0035",
    "less",
    "0",
    "0.01 at every modeled look",
    "1.00 at N=400; 0.95 at N=500,...,900",
    "0.981",
    "logrank",
    "FALSE",
    "300 evaluated",
    "20 per evaluated scenario"
  ),
  Status = c(
    "reported", "reported", "reported", "reported", "assumed",
    "inferred", "reported", "reported", "reported", "inferred",
    "reported", "reported", "reported", "reported", "reported",
    "inferred", "inferred", "reported", "inferred", "assumed", "assumed"
  ),
  `Source and mapping` = c(
    "ADR Sections 1.2 and 3",
    "ADR Section 3; maximum N is not an `interim_look` in `goldilocks`",
    "ADR Sections 1.4.1 and 3.3",
    "ADR Section 1.2; named package values identify control and treatment",
    "ADR reports varying blocks of 3, 6, or 9; a fixed block of 3 is the closest available specification",
    "ADR Sections 5.2 and 7 report a six-month ramp to a peak of 26/month",
    "ADR Section 2.1 reports 0-6, 6-12, 12-18, and >18 month intervals; the 16-month package horizon uses the first two cut-points",
    "ADR Table 5 uses 0-12, 12-24, and >24 month generating intervals; only the 12-month cut-point precedes the 16-month horizon",
    "ADR Table 5, using its two generating hazards that apply before the 16-month horizon",
    "ADR Sections 5.1 and 7 report the target hazard-ratio scenario",
    "ADR Sections 5.3 and 7.2; independent exponential dropout CDF of 0.10 at 16 months",
    "ADR Table 1; `goldilocks` applies these independent priors to both arms",
    "ADR Equation 1 defines lower treatment hazard as benefit",
    "ADR Equation 1 uses equality of survival distributions",
    "ADR Section 3.2",
    "ADR Section 3.3; 1.00 disables package success stopping at N=400",
    "1 minus the reported one-sided P-value threshold of 0.019",
    "ADR Section 1.4.1",
    "The reported final analysis uses observed right-censored data",
    "Illustrative setting; ADR Section 2.3.3 specifies at least 10,000 draws for actual interim analyses and 1,000 within design simulations",
    "Illustrative study uses 20 per scenario; ADR Section 5.5 used 1,000 trials per treatment-benefit scenario and 10,000 per null scenario"
  ),
  check.names = FALSE
)

knitr::kable(input_audit, format = "pipe")

## ----event-profile------------------------------------------------------------
weeks_per_month <- 52 / 12

sponsor_control_hazard_week <- c(0.00828, 0.00240, 0.00012)
sponsor_interval_length_week <- rep(52, 3)
control_event_probability_3y <- 1 - exp(-sum(
  sponsor_control_hazard_week * sponsor_interval_length_week
))

data.frame(
  Quantity = c("One-year control event probability", "Three-year control event probability"),
  Value = c(
    1 - exp(-0.00828 * 52),
    control_event_probability_3y
  )
)

## ----model-parameters---------------------------------------------------------
analysis_cutpoints_week <- c(6, 12) * weeks_per_month
generation_cutpoints_week <- 12 * weeks_per_month
end_of_study_week <- 16 * weeks_per_month

hazard_control_week <- c(0.00828, 0.00240)
hazard_treatment_target_week <- 0.70 * hazard_control_week
hazard_treatment_null_week <- hazard_control_week

prior_surv_approx <- rbind(
  shape = c(1, 1, 1),
  rate = c(1 / 0.0069, 1 / 0.0069, 1 / 0.0035)
)

## ----accrual-profile----------------------------------------------------------
peak_rate_per_month <- 26
ramp_rate_per_month <- c(
  peak_rate_per_month * seq(1, 11, by = 2) / 12,
  peak_rate_per_month
)
ramp_change_week <- (1:6) * weeks_per_month
ramp_rate_per_week <- ramp_rate_per_month / weeks_per_month

accrual_table <- data.frame(
  `Trial-calendar interval` = c(
    paste0("Month ", 1:6),
    "After month 6"
  ),
  `Approximate patients/month` = ramp_rate_per_month,
  `Patients/week supplied to goldilocks` = ramp_rate_per_week,
  check.names = FALSE
)

knitr::kable(accrual_table, digits = 3)

## ----accrual-projection, fig.height = 5.2-------------------------------------
plot_enrollment(
  lambda = ramp_rate_per_month,
  lambda_time = 1:6,
  N_total = 1000,
  end_of_study = 16,
  n_sim = 20,
  seed = 3425423,
  time_unit = "months",
  main = "Piecewise-constant accrual approximation"
)

## ----common-design------------------------------------------------------------
anthem_common <- list(
  cutpoints = analysis_cutpoints_week,
  generation_cutpoints = generation_cutpoints_week,
  N_total = 1000,
  lambda = ramp_rate_per_week,
  lambda_time = ramp_change_week,
  interim_look = seq(400, 900, by = 100),
  end_of_study = end_of_study_week,
  prior_surv = prior_surv_approx,
  block = 3,
  rand_ratio = c(control = 1, treatment = 2),
  prop_loss = 0.10,
  alternative = "less",
  h0 = 0,
  Fn = rep(0.01, 6),
  Sn = c(1, rep(0.95, 5)),
  prob_ha = 0.981,
  N_impute = 300,
  mc_conf_level = 0.95,
  empty_interval = "prior",
  method = "logrank",
  imputed_final = FALSE
)

## ----worked-trial-------------------------------------------------------------
set.seed(3425422)

anthem_trial <- do.call(survival_adapt, c(
  anthem_common,
  list(
    hazard_treatment = hazard_treatment_target_week,
    hazard_control = hazard_control_week,
    return_trace = TRUE
  )
))

anthem_trial$summary

## ----decision-trace-----------------------------------------------------------
trace_display <- anthem_trial$trace[c(
  "planned_N",
  "calendar_time",
  "events_treatment",
  "events_control",
  "ppp_stop_now",
  "success_threshold",
  "ppp_success_at_max",
  "futility_threshold",
  "decision"
)]

knitr::kable(
  trace_display,
  digits = 3,
  col.names = c(
    "N",
    "Time",
    "VNS events",
    "Control events",
    "PPSn",
    "Success cut",
    "PPSmax",
    "Futility cut",
    "Decision"
  )
)

## ----decision-trace-plot, fig.height = 8--------------------------------------
plot_trial_trace(anthem_trial)

## ----small-operating-characteristics------------------------------------------
anthem_alt <- do.call(sim_trials, c(
  anthem_common,
  list(
    hazard_treatment = hazard_treatment_target_week,
    hazard_control = hazard_control_week,
    N_trials = 20,
    ncores = 2,
    seed = 3425430
  )
))

anthem_null <- do.call(sim_trials, c(
  anthem_common,
  list(
    hazard_treatment = hazard_treatment_null_week,
    hazard_control = hazard_control_week,
    N_trials = 20,
    ncores = 2,
    seed = 3425431
  )
))

anthem_oc <- summarise_sims(list(
  "Null: HR = 1.00" = anthem_null,
  "Target: HR = 0.70" = anthem_alt
))

oc_display <- anthem_oc[c(
  "scenario",
  "n_used",
  "power",
  "power_mcse",
  "power_mc_lower",
  "power_mc_upper",
  "stop_success",
  "stop_futility",
  "mean_N",
  "mean_N_mcse"
)]

knitr::kable(
  oc_display,
  digits = 3,
  col.names = c(
    "Scenario", "Trials used", "Power", "Power MCSE",
    "Power lower 95% MC", "Power upper 95% MC", "Expected success stop",
    "Futility stop", "Mean N", "Mean N MCSE"
  )
)

