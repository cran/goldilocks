## ----include = FALSE----------------------------------------------------------
source("shared-vignette-resources.R")
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 4
)
set.seed(46012244)

## ----setup, message=FALSE-----------------------------------------------------
library(goldilocks)

## ----trial-summary, echo=FALSE------------------------------------------------
trial_summary <- data.frame(
  Feature = c(
    "Population",
    "Treatment arm",
    "Control arm",
    "Randomization",
    "Follow-up",
    "Adaptive sample sizes",
    "Primary effectiveness endpoint",
    "Primary safety endpoint"
  ),
  `Reported ADVENT design` = c(
    "Drug-resistant paroxysmal atrial fibrillation",
    "Pulsed field ablation",
    "Thermal ablation by radiofrequency or cryoballoon ablation",
    "1:1 after nonrandomized roll-in subjects",
    "12 months",
    "350, 450, 550, 650, or 750 mITT subjects",
    paste(
      "Treatment success: acute procedural success and freedom from",
      "specified chronic failures through 12 months"
    ),
    paste(
      "Composite device- or procedure-related serious adverse events,",
      "including selected acute and chronic events"
    )
  ),
  check.names = FALSE
)

knitr::kable(trial_summary)

## ----trial-flowchart, echo=FALSE, message=FALSE, out.width='100%'-------------
DiagrammeR::grViz("
digraph advent_trial_flow {
  graph [rankdir = TB, bgcolor = transparent, ranksep = 0.55, nodesep = 0.35]
  node  [shape = box, style = rounded, fontname = Helvetica, fontsize = 14,
         margin = 0.12]
  edge  [fontname = Helvetica, fontsize = 12]

  screen [label = 'Eligible patients\\nwith drug-resistant PAF']
  rollin [label = 'Site roll-in\\n1 to 3 PFA subjects']
  random [label = 'Randomized comparison\\n1:1 allocation']
  pfa    [label = 'PFA arm']
  thermal [label = 'Thermal ablation arm\\nRF or cryoballoon']
  blank  [label = '90-day blanking period']
  follow [label = 'Follow to 12 months']
  endpoints [label = 'Co-primary endpoints\\neffectiveness + safety']

  screen -> rollin
  rollin -> random
  random -> pfa
  random -> thermal
  pfa -> blank
  thermal -> blank
  blank -> follow
  follow -> endpoints
}
", width = "100%", height = "620px")

## ----adaptive-flowchart, echo=FALSE, message=FALSE, out.width='100%'----------
DiagrammeR::grViz("
digraph advent_goldilocks {
  graph [rankdir = TB, bgcolor = transparent, ranksep = 0.55, nodesep = 0.35]
  node  [shape = box, style = rounded, fontname = Helvetica, fontsize = 14,
         margin = 0.12]
  edge  [fontname = Helvetica, fontsize = 12]

  start [label = 'Start adaptive review\\nN = 350']
  high  [shape = diamond, label = 'Predicted success\\nhigh for both endpoints?']
  success [label = 'Stop enrollment\\ncurrent N is adequate']
  low   [shape = diamond, label = 'Predicted success\\nlow for either endpoint\\nat max N = 750?']
  futile [label = 'Stop enrollment\\nfutility']
  maxn  [shape = diamond, label = 'Reached\\nN = 750?']
  maxstop [label = 'Stop enrollment\\nmaximum reached']
  accrue [label = 'Accrue 100 more\\nmITT subjects']
  follow [label = 'Complete 12-month\\nfollow-up']
  final [label = 'Final Bayesian\\nnoninferiority analyses']

  start -> high
  high -> success [label = 'Yes']
  high -> low [label = 'No']
  low -> futile [label = 'Yes']
  low -> maxn [label = 'No']
  maxn -> maxstop [label = 'Yes']
  maxn -> accrue [label = 'No']
  accrue -> high
  success -> follow
  futile -> follow
  maxstop -> follow
  follow -> final
}
", width = "100%", height = "760px")

## ----sample-size-arguments----------------------------------------------------
N_total <- 750
interim_look <- c(350, 450, 550, 650)

Sn <- c(0.95, 0.90, 0.85, 0.80)
Fn <- c(0.05, 0.10, 0.10, 0.10)

## ----endpoint-table, echo=FALSE-----------------------------------------------
endpoint_map <- data.frame(
  Endpoint = c("Effectiveness", "Safety"),
  `Published scale` = c(
    "Treatment success by 12 months",
    "Primary safety event by 12 months"
  ),
  `Code event` = c(
    "Failure to meet treatment success",
    "Primary safety event"
  ),
  `Target event probability` = c(0.35, 0.08),
  `Noninferiority margin` = c(0.15, 0.08),
  `Posterior threshold` = c(0.956, 0.966),
  check.names = FALSE
)

knitr::kable(endpoint_map, digits = 3)

## ----beta-prior---------------------------------------------------------------
prior_bin <- c(0.5, 0.5)

## ----imputation-prior---------------------------------------------------------
prior_surv_effectiveness <- rbind(
  shape = c(0.5, 0.5, 0.5, 0.5, 5),
  rate = c(0.001, 0.001, 0.001, 0.001, 10000)
)
prior_surv_default <- c(shape = 0.5, rate = 0.001)
prior_surv_final <- prior_surv_default

## ----hazards------------------------------------------------------------------
days_per_month <- 30L
follow_up_months <- 12L
end_of_study_day <- follow_up_months * days_per_month

eff_event_cutpoints_day <- c(90, 104, 150, 210)
eff_hazard_per_day <- c(
  0.000111670,
  0.002197976,
  0.003163208,
  0.002839089,
  0.000494053
)

safety_event_cutpoints_day <- 7
safety_hazard_per_day <- c(0.011137363, 1.53540e-5)

event_free_at_interval_end <- function(hazard, interval_end) {
  vapply(seq_along(hazard), function(j) {
    cutpoints <- if (j == 1L) NULL else interval_end[seq_len(j - 1L)]
    1 - ppwe(
      hazard = matrix(hazard[seq_len(j)], nrow = 1L),
      cutpoints = cutpoints,
      end_of_study = interval_end[j]
    )
  }, numeric(1))
}

implied_event_free_proportion <- c(
  event_free_at_interval_end(
    eff_hazard_per_day,
    c(eff_event_cutpoints_day, end_of_study_day)
  ),
  event_free_at_interval_end(
    safety_hazard_per_day,
    c(safety_event_cutpoints_day, end_of_study_day)
  )
)

hazard_table <- data.frame(
  Endpoint = c(rep("Effectiveness failure", 5), rep("Safety event", 2)),
  `Follow-up interval (days)` = c(
    "0--<90", "90--<104", "104--<150", "150--<210",
    "210--360", "0--<7", "7--360"
  ),
  `Hazard per patient-day` = c(
    eff_hazard_per_day,
    safety_hazard_per_day
  ),
  `Implied event-free proportion at interval end` =
    implied_event_free_proportion,
  check.names = FALSE
)

knitr::kable(hazard_table, digits = c(9, 3))

## ----probability-check--------------------------------------------------------
prob_check <- data.frame(
  Endpoint = c("Effectiveness failure", "Safety event"),
  `SAP target event probability at day 360` = c(0.35, 0.08),
  `Calculated event probability at day 360` = c(
    ppwe(
      hazard = matrix(eff_hazard_per_day, nrow = 1),
      end_of_study = end_of_study_day,
      cutpoints = eff_event_cutpoints_day
    ),
    ppwe(
      hazard = matrix(safety_hazard_per_day, nrow = 1),
      end_of_study = end_of_study_day,
      cutpoints = safety_event_cutpoints_day
    )
  ),
  check.names = FALSE
)

knitr::kable(prob_check, digits = 6)

## ----scaled-hazards-----------------------------------------------------------
scale_pwe_to_event_probability <- function(
  hazard_per_day,
  cutpoints_day,
  end_day,
  target_event_probability
) {
  interval_length_day <- diff(c(0, cutpoints_day, end_day))
  cumulative_hazard <- sum(hazard_per_day * interval_length_day)
  scale <- -log1p(-target_event_probability) / cumulative_hazard
  hazard_per_day * scale
}

eff_margin_hazard_per_day <- scale_pwe_to_event_probability(
  eff_hazard_per_day,
  eff_event_cutpoints_day,
  end_of_study_day,
  target_event_probability = 0.50
)

safety_margin_hazard_per_day <- scale_pwe_to_event_probability(
  safety_hazard_per_day,
  safety_event_cutpoints_day,
  end_of_study_day,
  target_event_probability = 0.16
)

## ----accrual-and-missingness--------------------------------------------------
enrollment_rate_per_month <- c(2, 5, 10, 15, 20, 25, 30, 33)
enrollment_rate_change_month <- 1:7

enrollment_rate_per_day <- enrollment_rate_per_month / days_per_month
enrollment_rate_change_day <-
  enrollment_rate_change_month * days_per_month

# Independent exponential dropout CDFs at the 360-day per-subject horizon.
effectiveness_prop_loss <- 0.075
safety_prop_loss <- 0.05

enrollment_schedule <- data.frame(
  `Trial-calendar interval (months)` = c(
    paste("Month", 1:7),
    "Month 8 onward"
  ),
  `Trial-calendar interval (days since first patient in)` = c(
    paste0(
      (0:6) * days_per_month,
      "--<",
      (1:7) * days_per_month
    ),
    paste0(7 * days_per_month, " onward")
  ),
  `SAP rate (subjects/month)` = enrollment_rate_per_month,
  `Rate supplied to goldilocks (subjects/day)` = enrollment_rate_per_day,
  check.names = FALSE
)

knitr::kable(enrollment_schedule, digits = 4)

## ----effectiveness-fit--------------------------------------------------------
set.seed(4601)

# One simulated effectiveness-endpoint trial
advent_effectiveness <- survival_adapt(
  hazard_treatment = eff_hazard_per_day,
  hazard_control = eff_hazard_per_day,
  cutpoints = eff_event_cutpoints_day,
  N_total = N_total,
  lambda = enrollment_rate_per_day,
  lambda_time = enrollment_rate_change_day,
  interim_look = interim_look,
  end_of_study = end_of_study_day,
  prior_surv = prior_surv_effectiveness,
  prior_surv_final = prior_surv_final,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  block = 2,
  rand_ratio = c(control = 1, treatment = 1),
  prop_loss = effectiveness_prop_loss,
  alternative = "less",
  h0 = 0.15,
  Fn = Fn,
  Sn = Sn,
  prob_ha = 0.956,
  N_impute = 50,
  empty_interval = "prior",
  method = "bayes-bin",
  imputed_final = TRUE
)

advent_effectiveness

## ----safety-fit---------------------------------------------------------------
set.seed(4602)

# One simulated safety-endpoint trial
advent_safety <- survival_adapt(
  hazard_treatment = safety_hazard_per_day,
  hazard_control = safety_hazard_per_day,
  cutpoints = safety_event_cutpoints_day,
  N_total = N_total,
  lambda = enrollment_rate_per_day,
  lambda_time = enrollment_rate_change_day,
  interim_look = interim_look,
  end_of_study = end_of_study_day,
  prior_surv = prior_surv_default,
  prior_surv_final = prior_surv_final,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  block = 2,
  rand_ratio = c(control = 1, treatment = 1),
  prop_loss = safety_prop_loss,
  alternative = "less",
  h0 = 0.08,
  Fn = Fn,
  Sn = Sn,
  prob_ha = 0.966,
  N_impute = 50,
  empty_interval = "prior",
  method = "bayes-bin",
  imputed_final = TRUE
)

advent_safety

## ----common-design------------------------------------------------------------
advent_common <- list(
  N_total = N_total,
  lambda = enrollment_rate_per_day,
  lambda_time = enrollment_rate_change_day,
  interim_look = interim_look,
  end_of_study = end_of_study_day,
  prior_surv = prior_surv_default,
  prior_surv_final = prior_surv_final,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  block = 2,
  rand_ratio = c(control = 1, treatment = 1),
  alternative = "less",
  Fn = Fn,
  Sn = Sn,
  N_impute = 30,
  empty_interval = "prior",
  method = "bayes-bin",
  imputed_final = TRUE,
  ncores = 2
)

advent_effectiveness_args <- modifyList(advent_common, list(
  cutpoints = eff_event_cutpoints_day,
  prior_surv = prior_surv_effectiveness,
  prop_loss = effectiveness_prop_loss
))

advent_safety_args <- modifyList(advent_common, list(
  cutpoints = safety_event_cutpoints_day,
  prop_loss = safety_prop_loss
))

advent_effectiveness_args

## ----oc-small-----------------------------------------------------------------
set.seed(4610)

eff_target <- do.call(sim_trials, c(
  advent_effectiveness_args,
  list(
    N_trials = 500,
    hazard_treatment = eff_hazard_per_day,
    hazard_control = eff_hazard_per_day,
    h0 = 0.15,
    prob_ha = 0.956,
    return_trace = TRUE,
    seed = 4610
  )
))

eff_null_boundary <- do.call(sim_trials, c(
  advent_effectiveness_args,
  list(
    N_trials = 500,
    hazard_treatment = eff_margin_hazard_per_day,
    hazard_control = eff_hazard_per_day,
    h0 = 0.15,
    prob_ha = 0.956,
    seed = 4611
  )
))

oc_small <- summarise_sims(list(
  "target: equal 35% failure" = eff_target,
  "margin: PFA failure 50%" = eff_null_boundary
))

knitr::kable(
  oc_small[c(
    "scenario", "n_used", "n_failed", "power", "stop_success",
    "stop_futility", "stop_max_N", "mean_N"
  )],
  digits = 3,
  col.names = c(
    "Scenario", "Trials used", "Failed runs", "Success probability",
    "Expected success stop", "Futility stop", "Maximum N", "Mean N"
  )
)

## ----advent-oc-plot, fig.width=9, fig.height=4.5------------------------------
effect_by_scenario <- c(
  "target: equal 35% failure" = 0.35,
  "margin: PFA failure 50%" = 0.50
)
oc_small$true_pfa_event_probability <- unname(
  effect_by_scenario[oc_small$scenario]
)
plot_sim_ocs(
  oc_small,
  effect = "true_pfa_event_probability",
  xlab = "True 12-month PFA event probability"
)

## ----advent-stopping-plot, fig.width=7, fig.height=5--------------------------
plot_sim_stopping(eff_target)

## ----advent-decision-plot, fig.width=9, fig.height=8--------------------------
plot_sim_decisions(eff_target)

## ----full-calibration-template, eval=FALSE------------------------------------
# advent_effectiveness_full_args <- modifyList(advent_effectiveness_args, list(
#   N_impute = 5000,
#   ncores = 8
# ))
# 
# advent_safety_full_args <- modifyList(advent_safety_args, list(
#   N_impute = 5000,
#   ncores = 8
# ))
# 
# eff_target_full <- do.call(sim_trials, c(
#   advent_effectiveness_full_args,
#   list(
#     N_trials = 1000,
#     hazard_treatment = eff_hazard_per_day,
#     hazard_control = eff_hazard_per_day,
#     h0 = 0.15,
#     prob_ha = 0.956,
#     seed = 4620
#   )
# ))
# 
# eff_margin_full <- do.call(sim_trials, c(
#   advent_effectiveness_full_args,
#   list(
#     N_trials = 1000,
#     hazard_treatment = eff_margin_hazard_per_day,
#     hazard_control = eff_hazard_per_day,
#     h0 = 0.15,
#     prob_ha = 0.956,
#     seed = 4621
#   )
# ))
# 
# safety_target_full <- do.call(sim_trials, c(
#   advent_safety_full_args,
#   list(
#     N_trials = 1000,
#     hazard_treatment = safety_hazard_per_day,
#     hazard_control = safety_hazard_per_day,
#     h0 = 0.08,
#     prob_ha = 0.966,
#     seed = 4622
#   )
# ))
# 
# safety_margin_full <- do.call(sim_trials, c(
#   advent_safety_full_args,
#   list(
#     N_trials = 1000,
#     hazard_treatment = safety_margin_hazard_per_day,
#     hazard_control = safety_hazard_per_day,
#     h0 = 0.08,
#     prob_ha = 0.966,
#     seed = 4623
#   )
# ))
# 
# summarise_sims(list(
#   "effectiveness target" = eff_target_full,
#   "effectiveness margin" = eff_margin_full,
#   "safety target" = safety_target_full,
#   "safety margin" = safety_margin_full
# ))

## ----sap-reference-benchmarks, echo=FALSE-------------------------------------
sap_reference_benchmarks <- data.frame(
  Scenario = c(
    "Target: both endpoints at expected rates",
    "Effectiveness noninferiority boundary",
    "Safety noninferiority boundary"
  ),
  `Reported probability` = c(0.9635, 0.0487, 0.0528),
  `Probability meaning` = c(
    "Joint power",
    "Effectiveness type I error",
    "Safety type I error"
  ),
  `Mean mITT sample size` = c(504, 551, 457),
  check.names = FALSE
)

knitr::kable(sap_reference_benchmarks, digits = 4)

