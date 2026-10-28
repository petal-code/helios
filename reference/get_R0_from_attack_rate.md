# Back-solve R0 from a final attack rate via the final-size relation

Helper for
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md).
Solves `AR = 1 - exp(-R0 * AR)` explicitly for R0: rearranging gives
`R0 = -log(1 - AR) / AR` (R0 appears once after taking logs, so no
numerical root-finder is needed).

## Usage

``` r
get_R0_from_attack_rate(attack_rate)
```

## Arguments

- attack_rate:

  Numeric scalar, must be in (0, 1). `attack_rate = 0` gives 0/0,
  `attack_rate >= 1` gives log of \<= 0, both undefined.

## Value

Numeric scalar R0, or `NA` if `attack_rate` is outside (0, 1)

## See also

Other calibration:
[`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md),
[`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md),
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md),
[`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md),
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
[`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
