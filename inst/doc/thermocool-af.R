## ----include = FALSE----------------------------------------------------------
source("shared-vignette-resources.R")
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 4.8
)
set.seed(1030236)

## ----setup, message = FALSE---------------------------------------------------
library(goldilocks)

## ----decision-flow, echo = FALSE, message = FALSE, out.width = "100%"---------
DiagrammeR::grViz("
digraph thermocool_rule {
  graph [rankdir = TB, bgcolor = transparent, ranksep = 0.50, nodesep = 0.35]
  node [shape = box, style = rounded, fontname = Helvetica, fontsize = 13,
        margin = 0.11]
  edge [fontname = Helvetica, fontsize = 11]

  start [label = 'At look l, calculate\nP[n,l] and P[nmax,l]']
  q [shape = diamond, label = 'P[n,l] > Q[l]?']
  immediate [label = 'Stop\nDeclare immediate success']
  s [shape = diamond, label = 'P[n,l] > S[l]?']
  expected [label = 'Stop accrual\nComplete follow-up, then analyze']
  f [shape = diamond, label = 'P[nmax,l] < F[l]?']
  futile [label = 'Stop for futility\nBinding decision']
  continue [label = 'Continue accrual\nTo the next look']

  start -> q
  q -> immediate [label = 'Yes']
  q -> s [label = 'No: P[n,l] <= Q[l]']
  s -> expected [label = 'Yes']
  s -> f [label = 'No']
  f -> futile [label = 'Yes']
  f -> continue [label = 'No']
}
", width = "100%", height = "670px")

## ----stopping-thresholds------------------------------------------------------
N_total <- 230
interim_look <- c(150, 175, 200)

Qn <- rep(0.99, length(interim_look))
Sn <- c(0.90, 0.80, 0.80)
Fn <- rep(0.01, length(interim_look))

## ----input-audit, echo = FALSE------------------------------------------------
input_audit <- data.frame(
  Input = c(
    "`N_total`",
    "`interim_look`",
    "`Qn`",
    "`Sn`",
    "`Fn`",
    "Futility statistic",
    "Early-claim information gate",
    "Non-stopping 106-patient look",
    "`prob_ha`",
    "`method`, `alternative`, `h0`",
    "`prior_bin`",
    "`cutpoints`, `generation_cutpoints`, `end_of_study`",
    "Sponsor predictive hazard prior",
    "`prior_surv`, `prior_surv_final`",
    "`block`, `rand_ratio`",
    "`lambda`, `lambda_time`",
    "Failure-time generator",
    "Worked benefit scenario",
    "Published OC scenario grid",
    "Observed enrollment history",
    "Observed interval hazards",
    "Complete regulatory sensitivity suite",
    "`prop_loss`",
    "`imputed_final`",
    "`N_impute`",
    "Evaluated `N_trials`"
  ),
  Value = c(
    "230",
    "150, 175, 200",
    "0.99 at each look",
    "0.90, 0.80, 0.80",
    "0.01 at each look",
    "Package uses P[nmax,l] only",
    "Not represented",
    "Not represented as an actionable look",
    "0.98",
    "bayes-bin, less, 0",
    "Beta(1, 1) in both arms",
    "0.5 and 2 months; 9-month horizon",
    "Three arm-specific piecewise rates with a hierarchical prior",
    "Fixed Gamma(1, 1) approximation in each interval and arm",
    "11; control 4 : treatment 7",
    "2, 3, 5 patients/month; changes at months 2 and 4",
    "Base hazards 0.65, 0.161, 0.05/month, scaled to target success",
    "Treatment 0.45; control 0.20 chronic success",
    "Three null and eight benefit scenarios",
    "11 after year 1; 53 after year 2; 160 at analysis; 167 at close",
    "June 2008 failures divided by exposure within each interval",
    "Not publicly available in full",
    "0 in each arm",
    "TRUE",
    "100 for one trial; 40 for small OC simulations; 5,000 in validation template",
    "50 per scenario"
  ),
  Status = c(
    "reported", "reported", "reported", "reported", "reported",
    "assumed", "reported", "reported", "reported", "inferred",
    "reported", "reported", "reported", "assumed", "reported",
    "reported", "reported", "reported", "reported", "reported",
    "inferred", "unavailable", "assumed", "inferred", "assumed",
    "assumed"
  ),
  `Source and mapping` = c(
    "JAMA Statistical Methods and FDA advisory briefing",
    "JAMA Statistical Methods and FDA advisory briefing",
    "Reported early-claim boundary; package applies its strict > rule",
    "Reported expected-success accrual boundaries",
    "Reported numeric futility boundary",
    "The requested enhancement differs from ThermoCool's P[n,l] and P[nmax,l] rule",
    "FDA briefing and transcript report 4.5 months or 50% endpoint-complete",
    "FDA requested it after the mid-trial amendment; zero probability of stopping",
    "Historical success was at least 0.98; the package classifies success using its strict > comparison",
    "Failure is the modeled binary event, so benefit is a lower treatment failure probability",
    "FDA advisory transcript and sponsor briefing",
    "JAMA and FDA describe breaks at 2 weeks/0.5 months and 2 months",
    "FDA briefing discloses Exp(rate = 1) priors on the Gamma hyperparameters, but not a directly reproducible fixed package prior",
    "Assumed plug-in approximation that sets both Gamma hyperparameters to the mean, 1, of their disclosed Exp(rate = 1) hyperpriors; not the sponsor's hierarchical prior",
    "JAMA Study Design",
    "Berry et al., Section 5.8, p. 245; default simulation accrual schedule",
    "Berry et al., Section 5.8, pp. 244--245; common shape scaled to an arm-specific nine-month success probability",
    "One of the benefit cases in Berry et al., Table 5.19; selected for the worked example",
    "Berry et al., Tables 5.18--5.19",
    "FDA sponsor briefing; realized history retained only for comparison",
    "Derived from FDA SSED Table 8; descriptive observed-data rates, not planning assumptions",
    "The FDA briefing redacts its scenario table, and Berry et al. notes additional sensitivity simulations without enumerating all of them",
    "No random loss generator is reported for the published scenarios; observed exclusions are not equivalent to random censoring",
    "JAMA reports multiple imputation for incomplete outcomes; the available package analysis is an approximation",
    "The evaluated counts are run-time choices; Berry et al. reports 1,000 burn-in and 5,000 retained MCMC iterations, which are not identical to the package computation",
    "Illustrative choice; the sponsor briefing reports 10,000 trials per scenario, while Berry et al. reports 25,000 for its tabulated null simulations"
  ),
  check.names = FALSE
)

knitr::kable(input_audit, format = "pipe")

## ----analysis-model-----------------------------------------------------------
analysis_cutpoints_month <- c(0.5, 2)
effectiveness_horizon_month <- 9

prior_bin <- c(1, 1)

# Assumed plug-in approximation using the means of the disclosed Exp(1)
# hyperpriors; this is not the sponsor's hierarchical hazard prior.
prior_surv <- c(shape = 1, rate = 1)

## ----published-hazard-generator-----------------------------------------------
base_chronic_success <- 0.40
base_failure_hazard <- c(
  `0--0.5` = 0.65,
  `0.5--2` = 0.161,
  `2--9` = 0.05
)

hazard_for_success <- function(p) {
  stopifnot(length(p) == 1L, is.finite(p), p > 0, p < 1)
  base_failure_hazard * log(p) / log(base_chronic_success)
}

published_scenarios <- data.frame(
  Type = c(rep("Null", 3), rep("Benefit", 8)),
  `Treatment chronic success` = c(
    0.20, 0.40, 0.60,
    0.30, 0.40, 0.45, 0.50, 0.50, 0.60, 0.65, 0.70
  ),
  `Control chronic success` = c(
    0.20, 0.40, 0.60,
    0.20, 0.20, 0.20, 0.20, 0.40, 0.40, 0.40, 0.40
  ),
  check.names = FALSE
)

knitr::kable(published_scenarios, digits = 2)

## ----worked-planning-scenario-------------------------------------------------
worked_chronic_success <- c(treatment = 0.45, control = 0.20)

hazard_treatment <- hazard_for_success(worked_chronic_success["treatment"])
hazard_control <- hazard_for_success(worked_chronic_success["control"])

planning_hazards <- data.frame(
  Arm = c("Catheter ablation", "ADT control"),
  `Target nine-month chronic success` = unname(worked_chronic_success),
  `Hazard 0--0.5 months` = c(hazard_treatment[1], hazard_control[1]),
  `Hazard 0.5--2 months` = c(hazard_treatment[2], hazard_control[2]),
  `Hazard 2--9 months` = c(hazard_treatment[3], hazard_control[3]),
  check.names = FALSE
)

knitr::kable(planning_hazards, digits = 3)

## ----accrual-model------------------------------------------------------------
enrollment_rate_per_month <- c(
  months_0_to_2 = 2,
  months_2_to_4 = 3,
  months_4_plus = 5
)
enrollment_rate_change_month <- c(2, 4)

data.frame(
  `Trial-calendar interval` = c("0--2 months", "2--4 months", "4+ months"),
  `Patients per month` = enrollment_rate_per_month,
  check.names = FALSE
)

## ----descriptive-hazards------------------------------------------------------
fda_interval_data <- data.frame(
  arm = rep(c("treatment", "control"), each = 3),
  interval = rep(c("0--0.5", "0.5--2", "2--9"), 2),
  exposure_months = c(40.21, 104.17, 413.09, 23.27, 54.21, 90.46),
  failures = c(26, 3, 7, 13, 14, 20)
)
fda_interval_data$hazard_per_month <- with(
  fda_interval_data,
  failures / exposure_months
)

knitr::kable(fda_interval_data, digits = 4)

observed_hazard_treatment <- subset(
  fda_interval_data,
  arm == "treatment"
)$hazard_per_month
observed_hazard_control <- subset(
  fda_interval_data,
  arm == "control"
)$hazard_per_month

## ----hazard-comparison--------------------------------------------------------
hazard_comparison <- data.frame(
  Interval = names(base_failure_hazard),
  `Planning: treatment` = unname(hazard_treatment),
  `Observed: treatment` = observed_hazard_treatment,
  `Planning: control` = unname(hazard_control),
  `Observed: control` = observed_hazard_control,
  check.names = FALSE
)

knitr::kable(hazard_comparison, digits = 3)

## ----reported-probability-comparison------------------------------------------
interval_length_month <- diff(c(
  0,
  analysis_cutpoints_month,
  effectiveness_horizon_month
))

chronic_success_comparison <- data.frame(
  Arm = c("Catheter ablation", "ADT control"),
  `Published worked scenario` = unname(worked_chronic_success),
  `Implied by observed FDA interval rates` = c(
    exp(-sum(observed_hazard_treatment * interval_length_month)),
    exp(-sum(observed_hazard_control * interval_length_month))
  ),
  `JAMA Kaplan-Meier estimate` = c(0.66, 0.16),
  `FDA SSED Kaplan-Meier estimate` = c(0.64, 0.16),
  check.names = FALSE
)

knitr::kable(chronic_success_comparison, digits = 3)

## ----accrual-comparison-------------------------------------------------------
expected_enrollment <- function(month) {
  interval_time <- c(
    min(month, 2),
    max(min(month - 2, 2), 0),
    max(month - 4, 0)
  )
  1 + sum(enrollment_rate_per_month * interval_time)
}

accrual_comparison <- data.frame(
  Milestone = c(
    "After year 1",
    "After year 2",
    "First planned analysis",
    "Enrollment close"
  ),
  `Approximate trial month` = c(12, 24, 35, 36),
  `Reported cumulative enrollment` = c(11, 53, 160, 167),
  `Expected under published simulation default` = vapply(
    c(12, 24, 35, 36),
    expected_enrollment,
    numeric(1)
  ),
  check.names = FALSE
)

knitr::kable(accrual_comparison, digits = 0)

## ----observed-accrual-sensitivity---------------------------------------------
observed_enrollment_rate_per_month <- c(
  year_1 = (11 - 1) / 12,
  year_2 = (53 - 11) / 12,
  year_3 = (167 - 53) / 12
)
observed_enrollment_rate_change_month <- c(12, 24)

data.frame(
  `Trial-calendar interval` = c(
    "0--12 months",
    "12--24 months",
    "24--36 months"
  ),
  `Observed-history patients per month` =
    observed_enrollment_rate_per_month,
  check.names = FALSE
)

## ----one-trial----------------------------------------------------------------
set.seed(1030236)

thermocool_trial <- survival_adapt(
  hazard_treatment = hazard_treatment,
  hazard_control = hazard_control,
  cutpoints = analysis_cutpoints_month,
  generation_cutpoints = analysis_cutpoints_month,
  N_total = N_total,
  lambda = enrollment_rate_per_month,
  lambda_time = enrollment_rate_change_month,
  interim_look = interim_look,
  end_of_study = effectiveness_horizon_month,
  prior_surv = prior_surv,
  prior_surv_final = prior_surv,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  binary_imputation = "event-time",
  block = 11,
  rand_ratio = c(control = 4, treatment = 7),
  prop_loss = 0,
  alternative = "less",
  h0 = 0,
  Fn = Fn,
  Sn = Sn,
  Qn = Qn,
  prob_ha = 0.98,
  N_impute = 100,
  empty_interval = "prior",
  method = "bayes-bin",
  imputed_final = TRUE,
  return_trace = TRUE
)

knitr::kable(
  thermocool_trial$summary[, c(
    "N_enrolled",
    "ppp_success",
    "stop_immediate_success",
    "stop_expected_success",
    "stop_futility",
    "trial_success",
    "stopping_reason",
    "decision_time"
  )],
  digits = 3,
  col.names = c(
    "Enrolled N", "Predictive success", "Immediate success stop",
    "Expected success stop", "Futility stop", "Trial success",
    "Stopping reason", "Decision time"
  )
)

## ----one-trial-trace----------------------------------------------------------
knitr::kable(
  thermocool_trial$trace[, c(
    "look",
    "planned_N",
    "ppp_stop_now",
    "immediate_success_threshold",
    "success_threshold",
    "ppp_success_at_max",
    "futility_threshold",
    "decision"
  )],
  digits = 3,
  col.names = c(
    "Look", "Planned N", "PPSn", "Immediate success cut",
    "Expected success cut", "PPSmax", "Futility cut", "Decision"
  )
)

## ----small-oc-----------------------------------------------------------------
thermocool_design <- list(
  cutpoints = analysis_cutpoints_month,
  generation_cutpoints = analysis_cutpoints_month,
  N_total = N_total,
  lambda = enrollment_rate_per_month,
  lambda_time = enrollment_rate_change_month,
  interim_look = interim_look,
  end_of_study = effectiveness_horizon_month,
  prior_surv = prior_surv,
  prior_surv_final = prior_surv,
  prior_bin = prior_bin,
  bin_method = "quadrature",
  binary_imputation = "event-time",
  block = 11,
  rand_ratio = c(control = 4, treatment = 7),
  prop_loss = 0,
  alternative = "less",
  h0 = 0,
  Fn = Fn,
  Sn = Sn,
  Qn = Qn,
  prob_ha = 0.98,
  N_impute = 40,
  empty_interval = "prior",
  method = "bayes-bin",
  imputed_final = TRUE,
  N_trials = 50,
  ncores = 2,
  return_trace = TRUE
)

thermocool_benefit <- do.call(sim_trials, c(
  thermocool_design,
  list(
    hazard_treatment = hazard_treatment,
    hazard_control = hazard_control,
    seed = 1030236
  )
))

thermocool_null <- do.call(sim_trials, c(
  thermocool_design,
  list(
    hazard_treatment = hazard_control,
    hazard_control = hazard_control,
    seed = 1030237
  )
))

oc_small <- summarise_sims(list(
  "Published benefit: 0.45 vs 0.20" = thermocool_benefit,
  "Published null: 0.20 vs 0.20" = thermocool_null
))

oc_display <- oc_small[, c(
  "scenario",
  "n_analyzed",
  "power",
  "stop_immediate_success",
  "stop_success",
  "stop_futility",
  "stop_max_N",
  "mean_N"
)]
names(oc_display)[names(oc_display) == "stop_success"] <-
  "stop_expected_success"

knitr::kable(
  oc_display,
  digits = 3,
  col.names = c(
    "Scenario", "Trials analyzed", "Power", "Immediate success stop",
    "Expected success stop", "Futility stop", "Maximum N", "Mean N"
  )
)

## ----stopping-plot, fig.width = 7, fig.height = 5-----------------------------
plot_sim_stopping(thermocool_null)

## ----decision-plot, fig.width = 9, fig.height = 7-----------------------------
plot_sim_decisions(thermocool_null)

## ----full-validation, eval = FALSE--------------------------------------------
# thermocool_full_design <- modifyList(thermocool_design, list(
#   N_trials = 25000,
#   N_impute = 5000,
#   ncores = 8,
#   return_trace = FALSE
# ))
# 
# q_grid <- c(0.975, 0.99, 0.995, 1.00)
# 
# full_null <- lapply(seq_along(q_grid), function(i) {
#   do.call(sim_trials, c(
#     modifyList(thermocool_full_design, list(Qn = q_grid[i])),
#     list(
#       hazard_treatment = hazard_control,
#       hazard_control = hazard_control,
#       seed = 1031000 + i
#     )
#   ))
# })
# names(full_null) <- paste0("null 0.20 vs 0.20: Qn = ", q_grid)
# 
# full_benefit <- lapply(seq_along(q_grid), function(i) {
#   do.call(sim_trials, c(
#     modifyList(thermocool_full_design, list(Qn = q_grid[i])),
#     list(
#       hazard_treatment = hazard_treatment,
#       hazard_control = hazard_control,
#       seed = 1032000 + i
#     )
#   ))
# })
# names(full_benefit) <- paste0("benefit 0.45 vs 0.20: Qn = ", q_grid)
# 
# full_oc <- summarise_sims(c(full_null, full_benefit))
# full_oc[, c(
#   "scenario",
#   "n_analyzed",
#   "power",
#   "power_mcse",
#   "stop_immediate_success",
#   "stop_immediate_success_mcse",
#   "stop_success",
#   "stop_futility",
#   "stop_max_N",
#   "mean_N",
#   "mean_N_mcse"
# )]

