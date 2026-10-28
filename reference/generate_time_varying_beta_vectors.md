# Expand a transmission_fraction split and a beta_community vector into the five setting-specific beta vectors Helios needs

Given a time-varying beta_community vector and a fixed transmission
fraction split, this function derives the corresponding time-varying
beta values for all settings. Setting-specific betas are scaled relative
to beta_community using the transmission fraction ratios, producing five
vectors ready to pass into
[`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md).

## Usage

``` r
generate_time_varying_beta_vectors(
  transmission_fraction,
  beta_community_vector
)
```

## Arguments

- transmission_fraction:

  Named numeric vector with names `household`, `workplace`, `leisure`,
  `community`, summing to 1.

- beta_community_vector:

  Numeric vector, the time-varying community beta (one value per
  simulated day). Typically the `beta_community` column from the table
  returned by
  [`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md).

## Value

A named list with five numeric vectors, each the same length as
`beta_community_vector`: `beta_household`, `beta_workplace`,
`beta_school`, `beta_leisure`, `beta_community`. `beta_school` is always
identical to `beta_workplace`. Ready to pass directly into
`get_parameters(overrides = ...)` alongside
`time_varying_transmission_on = TRUE`.

## See also

Other calibration:
[`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md),
[`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md),
[`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md),
[`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md),
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
[`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
