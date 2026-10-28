# Update model parameters with intervention switches

Determines which locations have an intervention deployed. If
`intervention_joint_active` is TRUE, coverage is computed across the
workplace/school/leisure pool using
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md).
Otherwise, per-setting coverage is computed for each setting whose
`intervention_<setting>_active` flag is TRUE via
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md).

## Usage

``` r
generate_intervention_switches(parameters_list, variables_list)
```

## Arguments

- parameters_list:

  A list of model parameters as generated using
  [`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)

- variables_list:

  A list of model variables as generated using
  [`create_variables()`](https://mrc-ide.github.io/helios/reference/create_variables.md)

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md),
[`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md),
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md),
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md),
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md),
[`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
