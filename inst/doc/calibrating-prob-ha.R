## ----include = FALSE----------------------------------------------------------
options(rmarkdown.html_vignette.check_title = FALSE)
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 4.8
)
load("prob-ha-calibration.rda")

## ----setup, message = FALSE---------------------------------------------------
library(goldilocks)

## ----design-------------------------------------------------------------------
target_type1 <- 0.025
prob_ha_grid <- seq(0.965, 0.995, by = 0.005)
null_hazard <- prop_to_haz(0.30, endtime = 12)

calibration_design <- list(
  hazard_treatment = null_hazard,
  hazard_control = null_hazard,
  cutpoints = NULL,
  N_total = 300,
  lambda = 5,
  lambda_time = NULL,
  interim_look = seq(100, 275, 25),
  end_of_study = 12,
  prior_surv = c(0.1, 0.1),
  block = 2,
  rand_ratio = c(control = 1, treatment = 1),
  prop_loss = 0,
  alternative = "less",
  h0 = 0,
  Fn = rep(0.10, 8),
  Sn = c(1, rep(0.90, 7)),
  Qn = 1,
  N_impute = 100,
  method = "logrank",
  return_trace = FALSE,
  ncores = 8
)

## ----screening-code, eval = FALSE---------------------------------------------
# screening_seed <- 67201
# 
# screening_results <- lapply(prob_ha_grid, function(threshold) {
#   do.call(
#     sim_trials,
#     c(
#       calibration_design,
#       list(
#         prob_ha = threshold,
#         N_trials = 2000,
#         seed = screening_seed
#       )
#     )
#   )
# })
# names(screening_results) <- sprintf("prob_ha = %.3f", prob_ha_grid)
# 
# screening_summary <- summarise_sims(screening_results)
# screening_summary$prob_ha <- prob_ha_grid

## ----classify-----------------------------------------------------------------
classify_type1 <- function(summary, target) {
  ifelse(
    summary$power_mc_upper <= target,
    "controlled",
    ifelse(
      summary$power_mc_lower > target,
      "not controlled",
      "inconclusive"
    )
  )
}

calibration_screening$type1_status <- classify_type1(
  calibration_screening,
  target_type1
)

screening_display <- calibration_screening[c(
  "prob_ha",
  "n_used",
  "power",
  "power_mc_lower",
  "power_mc_upper",
  "type1_status"
)]
names(screening_display)[3:5] <- c(
  "type1_error",
  "type1_mc_lower",
  "type1_mc_upper"
)
knitr::kable(screening_display, digits = 3)

## ----calibration-plot, fig.alt="Estimated type I error and 95% Monte Carlo intervals across seven prob_ha candidates. The intervals for candidates 0.985, 0.990, and 0.995 fall below the horizontal 0.025 target."----
screening_plot <- calibration_screening[
  order(calibration_screening$prob_ha),
]
status_colours <- c(
  "controlled" = "#009E73",
  "inconclusive" = "#E69F00",
  "not controlled" = "#D55E00"
)
point_colours <- unname(status_colours[screening_plot$type1_status])
y_max <- max(screening_plot$power_mc_upper, target_type1) * 1.08

plot(
  screening_plot$prob_ha,
  screening_plot$power,
  type = "n",
  ylim = c(0, y_max),
  xlab = expression(prob[ha]),
  ylab = "Null rejection probability (estimated type I error)",
  main = "Screening prob_ha against a 0.025 target"
)
plot_region <- par("usr")
rect(
  plot_region[1],
  0,
  plot_region[2],
  target_type1,
  col = grDevices::adjustcolor("#009E73", alpha.f = 0.10),
  border = NA
)
abline(h = target_type1, col = "#0072B2", lty = 2, lwd = 2)
lines(screening_plot$prob_ha, screening_plot$power, col = "#555555")
arrows(
  screening_plot$prob_ha,
  screening_plot$power_mc_lower,
  screening_plot$prob_ha,
  screening_plot$power_mc_upper,
  angle = 90,
  code = 3,
  length = 0.04,
  col = point_colours
)
points(
  screening_plot$prob_ha,
  screening_plot$power,
  pch = 19,
  col = point_colours
)
legend(
  "topright",
  legend = c(names(status_colours), "target"),
  col = c(unname(status_colours), "#0072B2"),
  pch = c(19, 19, 19, NA),
  lty = c(NA, NA, NA, 2),
  bty = "n"
)

## ----selected-candidate-------------------------------------------------------
controlled_candidates <- calibration_screening$prob_ha[
  calibration_screening$type1_status == "controlled"
]
if (length(controlled_candidates) == 0L) {
  stop("No screened candidate meets the Monte Carlo criterion; revise the grid or simulation size.")
}
selected_prob_ha <- min(controlled_candidates)
selected_prob_ha

## ----validation-code, eval = FALSE--------------------------------------------
# validation_result <- do.call(
#   sim_trials,
#   c(
#     calibration_design,
#     list(
#       prob_ha = selected_prob_ha,
#       N_trials = 10000,
#       seed = 67202
#     )
#   )
# )
# 
# validation_summary <- summarise_sims(list(
#   "fresh-seed validation" = validation_result
# ))
# validation_summary$prob_ha <- selected_prob_ha
# validation_summary$type1_status <- classify_type1(
#   validation_summary,
#   target_type1
# )

## ----validation-result--------------------------------------------------------
validation_display <- calibration_validation[c(
  "prob_ha",
  "n_used",
  "power",
  "power_mc_lower",
  "power_mc_upper",
  "type1_status"
)]
names(validation_display)[3:5] <- c(
  "type1_error",
  "type1_mc_lower",
  "type1_mc_upper"
)
knitr::kable(validation_display, digits = 4)

## ----rmst-calibration-design--------------------------------------------------
rmst_calibration_design <- modifyList(calibration_design, list(
  method = "rmst",
  rmst_tau = 9,
  alternative = "greater",
  h0 = 0
))

