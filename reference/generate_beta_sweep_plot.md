# Plot sanity-check figures for a beta sweep result

Produces a two-panel base R plot: beta vs. back-solved R0 (with a
reference line at R0 = 1), and beta vs. attack rate with error bars
across replicates. Useful for a visual check that a sweep behaved
sensibly (monotonic R0, reasonable attack-rate spread) before using it
in
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md).

## Usage

``` r
generate_beta_sweep_plot(sweep_result)
```

## Arguments

- sweep_result:

  The list returned by
  [`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md)

## Value

Invisibly returns `NULL`. Called for its plotting side effect.

## See also

Other calibration:
[`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md),
[`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md),
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md),
[`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md),
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
[`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
