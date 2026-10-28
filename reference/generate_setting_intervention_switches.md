# Generate intervention switches for a particular setting

Helper to generate the 0/1 switch vector indicating which locations in
one setting receive the intervention (1 = covered, 0 = not covered), as
used in
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md).
Coverage is interpreted as the fraction of total size to cover (size
weighted either by number of individuals or by square footage).
Locations are picked until cumulative size meets the budget, either at
random or in decreasing order of riskiness.

## Usage

``` r
generate_setting_intervention_switches(
  parameters_list,
  variables_list,
  setting
)
```

## Arguments

- parameters_list:

  A list of model parameters as generated using
  [`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)

- variables_list:

  A list of model variables as generated using
  [`create_variables()`](https://mrc-ide.github.io/helios/reference/create_variables.md)

- setting:

  One of `"workplace"`, `"school"`, `"leisure"`, or `"household"`

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md),
[`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md),
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md),
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md),
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md),
[`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
