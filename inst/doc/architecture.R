## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----echo = FALSE, fig.width = 8, fig.height = 8, fig.alt = "Diagram showing the function call dependencies in the goldilocks package."----
DiagrammeR::grViz("
digraph goldilocks {

  graph [rankdir = TB, fontsize = 12, nodesep = 0.4, ranksep = 0.6]

  node [shape = box, style = 'filled, rounded', fontname = Helvetica, fontsize = 10]

  # Exported functions (blue)
  sim_trials       [label = 'sim_trials()',       fillcolor = '#dae8fc', color = '#6c8ebf']
  survival_adapt   [label = 'survival_adapt()',   fillcolor = '#dae8fc', color = '#6c8ebf']
  summarise_sims   [label = 'summarise_sims()',   fillcolor = '#dae8fc', color = '#6c8ebf']
  sim_comp_data    [label = 'sim_comp_data()',    fillcolor = '#dae8fc', color = '#6c8ebf']
  enrollment       [label = 'enrollment()',       fillcolor = '#dae8fc', color = '#6c8ebf']
  randomization    [label = 'randomization()',    fillcolor = '#dae8fc', color = '#6c8ebf']
  pwe_sim          [label = 'pwe_sim()',          fillcolor = '#dae8fc', color = '#6c8ebf']
  pwe_impute       [label = 'pwe_impute()',       fillcolor = '#dae8fc', color = '#6c8ebf']
  ppwe             [label = 'ppwe()',             fillcolor = '#dae8fc', color = '#6c8ebf']

  # Internal functions (grey)
  test_stop_success [label = 'test_stop_success()', fillcolor = '#f5f5f5', color = '#999999']
  test_final        [label = 'test_final()',         fillcolor = '#f5f5f5', color = '#999999']
  analyse_data      [label = 'analyse_data()',       fillcolor = '#f5f5f5', color = '#999999']
  impute_data       [label = 'impute_data()',        fillcolor = '#f5f5f5', color = '#999999']
  posterior          [label = 'posterior()',           fillcolor = '#f5f5f5', color = '#999999']
  haz_to_prop       [label = 'haz_to_prop()',        fillcolor = '#f5f5f5', color = '#999999']
  logrank_test      [label = 'logrank_test()',        fillcolor = '#f5f5f5', color = '#999999']

  # Edges
  sim_trials      -> survival_adapt
  sim_trials      -> summarise_sims  [style = dashed, label = 'output list']

  survival_adapt  -> sim_comp_data
  survival_adapt  -> posterior
  survival_adapt  -> test_stop_success
  survival_adapt  -> test_final

  sim_comp_data   -> enrollment
  sim_comp_data   -> randomization
  sim_comp_data   -> pwe_sim

  test_stop_success -> impute_data
  test_stop_success -> analyse_data

  test_final      -> posterior
  test_final      -> impute_data
  test_final      -> analyse_data

  analyse_data    -> posterior
  analyse_data    -> haz_to_prop
  analyse_data    -> logrank_test

  haz_to_prop     -> ppwe

  impute_data     -> pwe_impute
  impute_data     -> pwe_sim
}
")

