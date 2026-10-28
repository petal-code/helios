# get_setting_size

get_setting_size() retrieves the number of individuals in each
individual location within a setting type (e.g. number of individuals in
each workplace, school, or household). The function calculates these
from the list of model variables, and returns a vector of individual
location sizes.

Note that this function is not able to calculate the location sizes for
the leisure setting.

## Usage

``` r
get_setting_size(variables_list, setting)
```

## Arguments

- variables_list:

  A list of model variables as generated using
  [`create_variables()`](https://mrc-ide.github.io/helios/reference/create_variables.md)

- setting:

  One of `"workplace"`, `"school"`, or `"household"`

## See also

Other miscellaneous:
[`generate_betas()`](https://mrc-ide.github.io/helios/reference/generate_betas.md),
[`timestep_to_day()`](https://mrc-ide.github.io/helios/reference/timestep_to_day.md)
