# Construct an intervention object

Defines a single intervention that can be installed into one or more
settings via
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md).
The intervention's effect on per-location ventilation is encoded by
`delta_function`, which returns the extra equivalent ACH (eACH) the
intervention adds to each covered location. The function can either
return a constant (same delta for every covered location) or a value
that depends on the location's baseline ACH. Optional unit-to-unit
variation can be added via `variation`.

## Usage

``` r
make_intervention(
  name,
  delta_depends_on_baseline_ach = FALSE,
  delta_function = NULL,
  delta_params = list(),
  variation = FALSE,
  variation_params = list(),
  coverage = NULL
)
```

## Arguments

- name:

  A character string label for the intervention.

- delta_depends_on_baseline_ach:

  Logical. If `FALSE` (default), `delta_function` is called with no
  arguments — the same delta is applied to every covered location. If
  `TRUE`, `delta_function` is called with the location's baseline ACH as
  its first argument — delta varies per location.

- delta_function:

  A function returning the eACH that the intervention adds. When
  `delta_depends_on_baseline_ach = FALSE`, `delta_function` should take
  no arguments other than those in `delta_params`. When
  `delta_depends_on_baseline_ach = TRUE`, the first argument must be the
  baseline ACH. Required (must not be NULL).

- delta_params:

  A named list of additional arguments passed to `delta_function`.
  Default = [`list()`](https://rdrr.io/r/base/list.html).

- variation:

  Logical. If `TRUE`, each location's delta is multiplied by an
  independent lognormal draw with mean 1, so that unit-to-unit variation
  does not shift the mean delta. Default = `FALSE`.

- variation_params:

  A named list supplying `sdlog`, the standard deviation on the log
  scale of the lognormal multiplier (dimensionless; approximately the
  relative error for small values). Required when `variation = TRUE`.
  Default = [`list()`](https://rdrr.io/r/base/list.html).

- coverage:

  Numeric in `[0, 1]`. Fraction of total setting size to cover when the
  intervention is installed.

## Value

A named list with the seven fields above, used as the intervention
object used by
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md)
and the downstream pipeline.

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md),
[`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md),
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md),
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md),
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md),
[`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
