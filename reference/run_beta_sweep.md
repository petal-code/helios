# Run a beta_community sweep and back-solve R0 via the final-size method

Run a beta_community sweep and back-solve R0 via the final-size method

## Usage

``` r
run_beta_sweep(
  transmission_fraction,
  model_params,
  beta_community_range = c(0.01, 0.25),
  n_beta = 25L,
  population = NULL,
  n_reps = NULL,
  sim_time = NULL,
  n_cores = NULL,
  seed = 42L,
  out_file = NULL
)
```

## Arguments

- transmission_fraction:

  Named numeric vector with names `household`, `workplace`, `leisure`,
  `community`, summing to 1. Used to derive the setting-specific beta
  ratios relative to beta_community. `beta_school` is always set equal
  to `beta_workplace`.

- model_params:

  A parameters list from
  [`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)
  (e.g. `get_parameters(archetype = "flu")` or a fully custom
  `get_parameters(overrides = list(duration_exposed = ..., ...))`).
  Supplies natural history (`duration_exposed`, `duration_infectious`,
  hospitalization/death probabilities, etc.) and the defaults for
  `population`, `n_reps`, and `sim_time` below. Initial condition
  proportions are derived from `model_params$number_initial_S/E/I/R`
  relative to `model_params$human_population`, then rescaled to
  whichever `population` is actually used.

- beta_community_range:

  Numeric vector `c(min, max)` for the beta sweep. Default
  `c(0.01, 0.25)`.

- n_beta:

  Number of beta values to sweep, linearly spaced across
  `beta_community_range`. Default 25.

- population:

  Population size for all runs. If `NULL`, falls back to
  `model_params$human_population`.

- n_reps:

  Number of stochastic replicates per beta value. If `NULL`, falls back
  to 20.

- sim_time:

  Simulation length in days. If `NULL`, falls back to
  `model_params$simulation_time`.

- n_cores:

  Number of cores for parallel execution. If `NULL`, falls back to
  `min(detectCores() - 1, 10)`.

- seed:

  Random seed. Default 42.

- out_file:

  Optional file path to save the result via
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html). If `NULL`
  (default), the result is only returned, not saved.

## Value

A list with:

- `sweep_table`: data.frame with columns `beta_community`, `AR_mean`,
  `AR_sd`, `R0_fs_mean`, `R0_fs_sd` (fs = final-size). One row per swept
  beta value; `R0_fs_mean` and `R0_fs_sd` are `NA` for subcritical beta
  values (those that do not produce a self-sustaining epidemic).

- `args`: a named list recording every resolved argument used, for full
  reproducibility of the sweep.

- `call_time`: POSIXct timestamp of when the sweep was run.

## See also

Other calibration:
[`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md),
[`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md),
[`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md),
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md),
[`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md),
[`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
