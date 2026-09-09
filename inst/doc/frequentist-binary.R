## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
set.seed(6301)

## ----setup, message=FALSE-----------------------------------------------------
library(goldilocks)

## ----score-design-------------------------------------------------------------
end_of_study <- 12

result <- survival_adapt(
  hazard_treatment = prop_to_haz(0.05, endtime = end_of_study),
  hazard_control = prop_to_haz(0.10, endtime = end_of_study),
  N_total = 80,
  lambda = 10,
  interim_look = 40,
  end_of_study = end_of_study,
  alternative = "less",
  h0 = 0,
  Fn = 0.05,
  Sn = 0.90,
  prob_ha = 0.975,
  N_impute = 20,
  method = "riskdiff-fm"
)

result

