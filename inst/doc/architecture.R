## ----include = FALSE----------------------------------------------------------
source("shared-vignette-resources.R")
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----echo = FALSE, fig.width = 10, fig.height = 6.2, fig.alt = "Flowchart linking trial assumptions, simulated or observed interim data, posterior prediction, adaptive decisions, final analysis, and operating characteristics."----
DiagrammeR::grViz("
digraph statistical_workflow {
  graph [rankdir = TB, fontsize = 12, nodesep = 0.32, ranksep = 0.48]
  node [shape = box, style = 'filled,rounded', fontname = Helvetica,
        fontsize = 10, fillcolor = '#f5f5f5', color = '#777777']
  edge [fontname = Helvetica, fontsize = 9, color = '#666666']

  assumptions [label = 'Prespecified assumptions\nendpoint, accrual, treatment effect, missingness',
               fillcolor = '#dae8fc', color = '#6c8ebf']
  simulated [label = 'Simulated trial data']
  observed [label = 'Observed interim data cut']
  posterior [label = 'Posterior distribution of event-time hazards']
  current [label = 'Predict success after follow-up\nof currently enrolled participants']
  maximum [label = 'Predict success after enrollment\nto the maximum sample size']
  decision [label = 'Apply Qn, Sn, and Fn\nimmediate success / expected success / futility / continue',
            fillcolor = '#fff2cc', color = '#d6b656']
  final [label = 'Prespecified final analysis\nwhen required']
  repeated [label = 'Repeat under null and alternative scenarios']
  oc [label = 'Operating characteristics\ntype I error, power, stopping, sample size, duration',
      fillcolor = '#d5e8d4', color = '#82b366']

  assumptions -> simulated
  assumptions -> posterior [style = dashed, label = 'analysis priors']
  simulated -> posterior [label = 'interim data']
  observed -> posterior
  posterior -> current
  posterior -> maximum
  current -> decision
  maximum -> decision
  decision -> final [label = 'expected success or maximum N']
  decision -> repeated [label = 'terminal trial result']
  final -> repeated
  repeated -> oc
}
")

## ----echo = FALSE, fig.width = 10, fig.height = 4.6, fig.alt = "Flowchart linking a single trial, repeated simulations, or an observed interim analysis to the corresponding summaries and graphical assessments."----
DiagrammeR::grViz("
digraph summaries {
  graph [rankdir = LR, fontsize = 12, nodesep = 0.28, ranksep = 0.45]
  node [shape = box, style = 'filled,rounded', fontname = Helvetica,
        fontsize = 9, fillcolor = '#f5f5f5', color = '#777777']
  edge [fontname = Helvetica, fontsize = 8, color = '#666666']

  one [label = 'One simulated trial\nsurvival_adapt()',
       fillcolor = '#dae8fc', color = '#6c8ebf']
  many [label = 'Repeated simulated trials\nsim_trials()',
        fillcolor = '#dae8fc', color = '#6c8ebf']
  observed [label = 'Observed interim data\nevaluate_interim()',
            fillcolor = '#dae8fc', color = '#6c8ebf']

  trace [label = 'Interim decision history\nsummarise_trial_trace() / plot_trial_trace()']
  enrollment [label = 'Enrollment and calendar time\nplot_enrollment() / summarise_calendar_time()']
  oc [label = 'Operating characteristics\nsummarise_sims() / plot_sim_ocs()']
  stopping [label = 'Stopping and decision regions\nplot_sim_stopping() / plot_sim_decisions()']

  one -> trace
  one -> enrollment
  observed -> trace
  many -> enrollment
  many -> oc
  many -> stopping
}
")

