# Run a single simulation replicate at a fixed beta_community value

Helper for
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md).
Builds the parameter list for one replicate and returns its final attack
rate.

## Usage

``` r
run_one_sweep_replicate(
  beta,
  seed,
  population,
  initial_S,
  initial_E,
  initial_I,
  initial_R,
  sim_time,
  household_ratio,
  workplace_ratio,
  school_ratio,
  leisure_ratio,
  model_params
)
```

## Arguments

- beta:

  beta_community value for this replicate

- seed:

  Seed for this replicate, passed through to `parameters_list$seed`

- population:

  Population size

- initial_S, initial_E, initial_I, initial_R:

  Initial compartment counts

- sim_time:

  Simulation length in days

- household_ratio, workplace_ratio, school_ratio, leisure_ratio:

  Setting-specific beta ratios relative to beta_community

- model_params:

  Base parameters list supplying natural history and other non-swept
  parameters

## Value

Numeric scalar: final attack rate (fraction of population ultimately
infected). Includes R, D, E, I_mild, and I_hosp compartments so the
estimate is robust when sim_time is short and the epidemic has not fully
resolved.

## See also

Other calibration:
[`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md),
[`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md),
[`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md),
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md),
[`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md),
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md)
