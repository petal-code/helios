# Establish the list of model parameters

This function creates a named list of model parameters which are to be
used in the model. For example, the output of `get_parameters()`
provides input to functions such as
[`create_variables()`](https://mrc-ide.github.io/helios/reference/create_variables.md)
and
[`create_events()`](https://mrc-ide.github.io/helios/reference/create_events.md).

## Usage

``` r
get_parameters(overrides = list(), archetype = "none")
```

## Arguments

- overrides:

  A named list of parameters values to be used instead of the defaults.
  These parameters are:

  - `human_population`: the number of humans to include in the model

  - `initial_proportion_child`: proportion of population initially in
    the 'child' age class

  - `initial_proportion_adult`: proportion of population initially in
    the 'adult' age class

  - `initial_proportion_elderly`: proportion of population initially in
    the 'elderly' age class

  - `number_initial_S`: number of humans initially Susceptible (state =
    S)

  - `number_initial_E`: number of humans initially Exposed (state = E)

  - `number_initial_I`: number of humans initially Infectious (state =
    I)

  - `number_initial_R`: number of humans initially Recovered (state = R)

  - `seed`: a seed to run the simulation with

  - `mean_household_size`: TBD

  - `workplace_prop_max`: maximum size of a workplace as a proportion of
    total adult population size

  - `workplace_a`: the a parameter for the Zipf-like distribution on
    workplace size

  - `workplace_c`: the c parameter for the Zipf-like distribution on
    workplace size

  - `school_prop_max`: maximum size of a school as a proporiton of total
    child population size

  - `school_meanlog`: the meanlog parameter for the log-normal
    distribution on school size

  - `school_sdlog`: the sdlog parameter for the log-normal distribution
    on school size

  - `school_student_staff_ratio`: the number of students to each adult
    staff member

  - `leisure_mean_number_settings`: TBD

  - `leisure_mean_size`: TBD

  - `leisure_overdispersion_size`: TBD

  - `leisure_prop_max`: TBD

  - `duration_exposed`: TBD

  - `duration_infectious`: TBD

  - `prob_inf_external`: The probability a susceptible individual is
    infected from an external source

  - `beta_household`: The transmission rate for household contacts, used
    to compute the per-timestep force of infection in household
    settings. A numeric scalar when `time_varying_transmission_on` is
    `FALSE`, or a numeric vector of length `simulation_time` (one value
    per simulated calendar day) when it is `TRUE`.

  - `beta_workplace`: The transmission rate for workplace contacts, used
    to compute the per-timestep force of infection in workplace
    settings. A numeric scalar when `time_varying_transmission_on` is
    `FALSE`, or a numeric vector of length `simulation_time` (one value
    per simulated calendar day) when it is `TRUE`.

  - `beta_school`: The transmission rate for school contacts, used to
    compute the per-timestep force of infection in school settings. A
    numeric scalar when `time_varying_transmission_on` is `FALSE`, or a
    numeric vector of length `simulation_time` (one value per simulated
    calendar day) when it is `TRUE`.

  - `beta_leisure`: The transmission rate for leisure contacts, used to
    compute the per-timestep force of infection in leisure settings. A
    numeric scalar when `time_varying_transmission_on` is `FALSE`, or a
    numeric vector of length `simulation_time` (one value per simulated
    calendar day) when it is `TRUE`.

  - `beta_community`: The transmission rate for community contacts, used
    to compute the per-timestep force of infection in community
    settings. A numeric scalar when `time_varying_transmission_on` is
    `FALSE`, or a numeric vector of length `simulation_time` (one value
    per simulated calendar day) when it is `TRUE`.

  - `time_varying_transmission_on`: Logical flag (default `FALSE`). When
    `FALSE`, each setting-specific beta must be a numeric scalar. When
    `TRUE`, each setting-specific beta must instead be a numeric vector
    of length `simulation_time`, giving that setting's beta for each
    simulated calendar day.

  - `dt`: TBD

  - `simulation_time`: TBD

  - `household_distribution_country`: TBD

  - `school_distribution_country`: TBD

  - `workplace_distribution_country`: TBD

  - `endemic_or_epidemic`: TBD

  - `duration_immune`: TBD

  - `prob_inf_external`: TBD

  Rendering Parameters

  - `render_diagnostics`: FALSE

  Setting-Specific ACH Parameters (ACH values are numeric, in air
  changes per hour; the distribution is truncated at 0, so the realised
  mean ACH is somewhat higher than the `_mean` parameter when the sd is
  large relative to the mean):

  - `setting_specific_ach_workplace`: boolean switch set to TRUE if
    setting-specific ACH parameterised in the workplace setting using
    [`set_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/set_setting_specific_ach.md);
    default = FALSE

  - `setting_specific_ach_workplace_mean`: The mean of the truncated
    normal distribution from which the setting-specific ACH of
    individual workplaces is drawn; default = 3.1

  - `setting_specific_ach_workplace_sd`: The standard deviation of the
    truncated normal distribution from which the setting-specific ACH of
    individual workplaces is drawn; default = 2.35

  - `setting_specific_ach_school`: boolean switch set to TRUE if
    setting-specific ACH parameterised in the school setting using
    [`set_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/set_setting_specific_ach.md);
    default = FALSE

  - `setting_specific_ach_school_mean`: The mean of the truncated normal
    distribution from which the setting-specific ACH of individual
    schools is drawn; default = 3.3

  - `setting_specific_ach_school_sd`: The standard deviation of the
    truncated normal distribution from which the setting-specific ACH of
    individual schools is drawn; default = 1.95

  - `setting_specific_ach_leisure`: boolean switch set to TRUE if
    setting-specific ACH parameterised in the leisure setting using
    [`set_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/set_setting_specific_ach.md);
    default = FALSE

  - `setting_specific_ach_leisure_mean`: The mean of the truncated
    normal distribution from which the setting-specific ACH of
    individual leisure locations is drawn; default = 3.5

  - `setting_specific_ach_leisure_sd`: The standard deviation of the
    truncated normal distribution from which the setting-specific ACH of
    individual leisure settings is drawn; default = 2.73

  - `setting_specific_ach_household`: boolean switch set to TRUE if
    setting-specific ACH parameterised in the household setting using
    [`set_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/set_setting_specific_ach.md);
    default = FALSE

  - `setting_specific_ach_household_mean`: The mean of the truncated
    normal distribution from which the setting-specific ACH of
    individual households is drawn; default = 2.0

  - `setting_specific_ach_household_sd`: The standard deviation of the
    truncated normal distribution from which the setting-specific ACH of
    individual households is drawn; default = 0.80

  Default (Uniform) ACH Parameters (used when
  `setting_specific_ach_<setting>` is FALSE. If
  `setting_specific_ach_<setting>` is FALSE and `default_ach_<setting>`
  is NULL,
  [`generate_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/generate_setting_specific_ach.md)
  errors rather than assuming a baseline):

  - `default_ach_workplace`: uniform ACH assigned to every workplace
    location when `setting_specific_ach_workplace` is FALSE. Set via
    [`set_default_ach()`](https://mrc-ide.github.io/helios/reference/set_default_ach.md).
    Default = 3.1.

  - `default_ach_school`: uniform ACH assigned to every school location
    when `setting_specific_ach_school` is FALSE. Default = 3.3.

  - `default_ach_leisure`: uniform ACH assigned to every leisure
    location when `setting_specific_ach_leisure` is FALSE. Default =
    3.5.

  - `default_ach_household`: uniform ACH assigned to every household
    location when `setting_specific_ach_household` is FALSE. Default =
    2.0.

  Indoor Air Volume Per Person Parameters (used in the Wells-Riley
  calculation, which assumes a well-mixed enclosed space; units: m^3 per
  person):

  - `volume_per_person_workplace`: average indoor air volume per person
    in a workplace; default = 27 (assumes ~10 m^2 floor area at 2.7 m
    height)

  - `volume_per_person_school`: average indoor air volume per person in
    a school; default = 10 (assumes ~3.33 m^2 floor area at 3 m height)

  - `volume_per_person_leisure`: average indoor air volume per person in
    a leisure setting; default = 8 (assumes ~2 m^2 floor area at 4 m
    height)

  - `volume_per_person_household`: average indoor air volume per person
    in a household; default = 50 (assumes ~20 m^2 floor area at 2.5 m
    height)

  Wells-Riley Parameters (used by
  [`convert_ach_to_riskiness()`](https://mrc-ide.github.io/helios/reference/convert_ach_to_riskiness.md)
  to derive per-location riskiness from ACH, and by
  [`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md)
  to derive per-location intervention efficacy from ACH and the
  intervention delta - the extra equivalent ACH an intervention adds to
  covered locations, see
  [`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md)):

  - `wells_riley_emission_rate`: rate at which an infectious individual
    emits airborne infectious units (denoted pi); units = FFU
    (focus-forming units)/hour; default = 365 (Blatchley & Cui 2023,
    Table 2, scenario C: speaking; scenario D, singing, is 2335)

  - `wells_riley_decay_rate`: natural decay rate of airborne pathogens
    (denoted k_D); units = 1/hour; default = 0.64 (Blatchley & Cui 2023)

  - `wells_riley_infection_prob_per_ffu`: probability of infection per
    inhaled FFU (focus-forming unit) (denoted r); units = 1/FFU; default
    = 1.37e-2, an exponential fit to Killingley et al. (2022), in which
    10 TCID50 (55 FFU) infected 18 of 34 volunteers:
    `-log(1 - 18/34) / 55`

  - `wells_riley_respiratory_rate_factor`: respiratory rate multiplied
    by tidal volume (denoted RR_tv); units = m^3/hour; default = 0.45
    (15 breaths/minute at 500 ml)

  - `wells_riley_time_in_room`: exposure window used inside the
    Wells-Riley calculation (denoted t); units = hours; default = 4

  `r` and `pi` are a matched pair: `1/r` = 73 FFU is one Wells-Riley
  quantum, so `pi` = 365 is 5.0 quanta/hour. Both consumers return
  ratios and the exponent is small, so this level has limited leverage
  over efficacy between scenarios A and C (0.60 at A versus 0.52-0.58
  across A-C in schools), but a substantially higher emission rate such
  as scenario D lowers it considerably (0.23 in schools).

  Intervention Parameters (populated internally by
  [`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md)
  and by
  [`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md);
  users do not normally set these directly. One block per scope, where
  `<s>` is one of `joint`, `workplace`, `school`, `leisure` or
  `household`):

  - `intervention_<s>_active`: boolean flag set to TRUE when an
    intervention has been installed in scope ~~. Default = FALSE~~

  - `intervention_<s>_list`: list of intervention objects (each as
    returned by
    [`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md))
    deployed in scope ~~. Currently single-intervention only — list
    always has length 1 when active. Default = NULL~~

  - `intervention_<s>_coverage`: fraction of total setting size to cover
    (numeric in `[0, 1]`); inherited from the intervention object's
    `coverage` field. Default = NULL

  - `intervention_<s>_coverage_target`: what the coverage fraction
    applies to. Either "individuals" or "square_footage". Default = NULL

  - `intervention_<s>_coverage_type`: how locations are selected for
    coverage. Either "random" (uniform sampling) or "targeted_riskiness"
    (locations ranked in decreasing order of riskiness). Default = NULL

  - `intervention_<s>_timestep`: first simulation timestep at which the
    intervention's efficacy is applied in the FOI calculation. Default =
    NULL

  - `intervention_<setting>_covered` (per-setting scopes only —
    workplace/school/leisure/household): 0/1 switch vector of length
    equal to the number of locations in the setting, populated by
    [`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md)
    to mark which locations received the intervention. Default = NULL

  Setting-Specific Room Size Per Individual Parameters:

  - `size_per_individual_workplace`: The volume or surface area for each
    individual in the workplace setting type; default = 1 (in which case
    "square_footage" coverage_target gives same results as "individuals"
    coverage_target)

  - `size_per_individual_school`: The volume or surface area for each
    individual in the school setting type; default = 1 (in which case
    "square_footage" coverage_target gives same results as "individuals"
    coverage_target)

  - `size_per_individual_leisure`: The volume or surface area for each
    individual in the leisure setting type; default = 1 (in which case
    "square_footage" coverage_target gives same results as "individuals"
    coverage_target)

  - `size_per_individual_household`: The volume or surface area for each
    individual in the household setting type; default = 1 (in which case
    "square_footage" coverage_target gives same results as "individuals"
    coverage_target)

  Hospitalizations and Deaths

  - `prob_hosp_child`: Probability that an infected child is
    hospitalized

  - `prob_hosp_adult`: Probability that an infected adult is
    hospitalized

  - `prob_hosp_elderly`: Probability that an infected elderly individual
    is hospitalized

  - `prob_death_hosp_child`: Probability of death for a hospitalized
    child, conditional on hospitalization

  - `prob_death_hosp_adult`: Probability of death for a hospitalized
    adult, conditional on hospitalization

  - `prob_death_hosp_elderly`: Probability of death for a hospitalized
    elderly individual, conditional on hospitalization

  - `duration_hospitalized`: Average duration (in days) of a
    hospitalization

- archetype:

  A text string indicating the pathogen archetype parameter set to load
  (default = "none", current options are flu, sars_cov_2, and measles)
