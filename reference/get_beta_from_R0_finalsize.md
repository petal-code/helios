# Map a target R0 (or Rt(t) series) to beta_community via final-size data

Prints a summary of the transmission fractions used in the underlying
sweep, the results table, and a plot of the mapped beta_community values
across the target sequence, then returns that same table.

## Usage

``` r
get_beta_from_R0_finalsize(
  target,
  sweep_db,
  linear_threshold = 1.2,
  min_linear_points = 3L
)
```

## Arguments

- target:

  Numeric scalar (a single target R0) or numeric vector (an Rt(t) time
  series). Values \> 1 are interpolated against the final-size table;
  values \<= 1 use a linear extrapolation fit to swept points near the
  epidemic threshold (see `linear_threshold` and `min_linear_points`).

- sweep_db:

  Either the list object returned by
  [`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
  or a file path (character string) to an `.rds` file saved by it.

- linear_threshold:

  R0 value defining the upper boundary of the near-threshold region used
  to fit the linear extrapolation. All swept points with R0 \<=
  `linear_threshold` are used if there are at least `min_linear_points`
  of them; otherwise the `min_linear_points` swept points closest to R0
  = 1 are used instead. Default 1.2.

- min_linear_points:

  Minimum number of points required in the near-threshold region before
  falling back to the closest-points approach. Default 3.

## Value

A data.frame with one row per element of `target`, and columns:

- `index`: position within `target` (useful for an Rt(t) series)

- `target_R0`: the R0 or Rt value supplied

- `beta_community`: the corresponding beta_community value

- `source`: `"sweep_data"` if `target_R0 > 1` (interpolated directly
  from the sweep), or `"linear_extrapolation"` if `target_R0 <= 1`

## Details

Note: this method assumes a fully susceptible population. When applied
to an Rt(t) series, each value is looked up independently against the
static beta-R0 relationship and does not account for time-varying
susceptible depletion interacting with a changing Rt.

## See also

Other calibration:
[`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md),
[`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md),
[`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md),
[`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md),
[`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md),
[`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
