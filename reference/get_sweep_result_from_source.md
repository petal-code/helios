# Load a sweep result from a run_beta_sweep() result or a saved file

Helper for
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md).
Accepts either the list object returned directly by
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
or a file path to an `.rds` file saved by it, and returns that list
either way.

## Usage

``` r
get_sweep_result_from_source(sweep_db)
```

## Arguments

- sweep_db:

  The list returned by
  [`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
  or a character file path to an `.rds` file containing that list

## Value

The full list returned by
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md)
(containing `sweep_table`, `args`, and `call_time`)

## See also

Other calibration:
[`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md),
[`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md),
[`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md),
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md),
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
[`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
