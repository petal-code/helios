# generate_betas

generate_betas() takes a beta_community and returns beta_household,
beta_school, beta_workplace, and beta_leisure given user-defined ratios.
The function also calculates the total beta value and returns the
proportion of the total corresponding to each setting. The beta values
are key inputs in the parameters_list as generated using the
[`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)
function. The function returns a dataframe containing the beta values
and their proportions of the total betas.

## Usage

``` r
generate_betas(
  beta_community,
  household_ratio,
  school_ratio,
  workplace_ratio,
  leisure_ratio
)
```

## Arguments

- beta_community:

  The beta value, or values, for the community setting for which the
  user wants to generate corresponding household, school, workplace, and
  leisure settings.

- household_ratio:

  The household beta as a ratio to the community beta

- school_ratio:

  The school beta as a ratio to the community beta

- workplace_ratio:

  The workplace beta as a ratio to the community beta

- leisure_ratio:

  The leisure beta as a ratio to the community beta

## See also

Other miscellaneous:
[`get_setting_size()`](https://mrc-ide.github.io/helios/reference/get_setting_size.md),
[`timestep_to_day()`](https://mrc-ide.github.io/helios/reference/timestep_to_day.md)
