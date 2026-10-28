# Generate joint intervention switches

Helper to generate joint intervention coverage across the workplace,
school, and leisure pool (household is excluded from joint deployment by
convention). Pools location sizes into a single budget, picks locations
until cumulative size meets the target coverage, and splits the result
back into per-setting 0/1 switch vectors stored at
`intervention_<setting>_covered`.

## Usage

``` r
generate_joint_intervention_switches(parameters_list, variables_list)
```

## Arguments

- parameters_list:

  A list of model parameters as generated using
  [`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)

- variables_list:

  A list of model variables as generated using
  [`create_variables()`](https://mrc-ide.github.io/helios/reference/create_variables.md)

## Details

Also propagates the joint intervention list and timestep into the
per-setting state so that downstream efficacy calculation runs uniformly
via the per-setting code path.

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md),
[`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md),
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md),
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md),
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md),
[`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
