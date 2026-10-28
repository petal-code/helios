# Package index

## Parameters

- [`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)
  : Establish the list of model parameters

## Variables

- [`create_variables()`](https://mrc-ide.github.io/helios/reference/create_variables.md)
  : Generate a list of the model variables
- [`generate_initial_age_classes()`](https://mrc-ide.github.io/helios/reference/generate_initial_age_classes.md)
  : Generates a vector of the age classes of all individuals in the
  population
- [`generate_initial_disease_states()`](https://mrc-ide.github.io/helios/reference/generate_initial_disease_states.md)
  : Generate a vector of the initial disease states of all individuals
  in the population
- [`generate_initial_households()`](https://mrc-ide.github.io/helios/reference/generate_initial_households.md)
  : Generates a vector of households for all individuals in the
  population
- [`generate_initial_households_bootstrap()`](https://mrc-ide.github.io/helios/reference/generate_initial_households_bootstrap.md)
  : Generates a vector of households for all individuals in the
  population
- [`generate_initial_leisure()`](https://mrc-ide.github.io/helios/reference/generate_initial_leisure.md)
  : Generate a list of leisure settings that each individual visits
- [`generate_initial_schools()`](https://mrc-ide.github.io/helios/reference/generate_initial_schools.md)
  : Generate a vector of school assignments for all individuals in the
  population
- [`generate_initial_schools_bootstrap()`](https://mrc-ide.github.io/helios/reference/generate_initial_schools_bootstrap.md)
  : Generate a vector of school assignments for all individuals in the
  population
- [`generate_initial_workplaces()`](https://mrc-ide.github.io/helios/reference/generate_initial_workplaces.md)
  : Gets workplace assignments for all individuals in the population

## Processes

- [`create_EI_process()`](https://mrc-ide.github.io/helios/reference/create_EI_process.md)
  : Create process governing exposed to infectious disease state
  transition
- [`create_I_hosp_exit_process()`](https://mrc-ide.github.io/helios/reference/create_I_hosp_exit_process.md)
  : Create process governing I_hosp -\> R or D disease state transition
- [`create_I_mild_R_process()`](https://mrc-ide.github.io/helios/reference/create_I_mild_R_process.md)
  : Create process governing I_mild -\> R disease state transition
- [`create_RS_process()`](https://mrc-ide.github.io/helios/reference/create_RS_process.md)
  : Create process governing recovered (and immune) back to susceptible
  disease state transition
- [`create_SE_process()`](https://mrc-ide.github.io/helios/reference/create_SE_process.md)
  : Create process governing susceptible to exposed disease state
  transition
- [`create_external_source_process()`](https://mrc-ide.github.io/helios/reference/create_external_source_process.md)
  : Create process governing exposed to infectious disease state
  transition
- [`create_processes()`](https://mrc-ide.github.io/helios/reference/create_processes.md)
  : Define and create all model processes

## Events

- [`create_events()`](https://mrc-ide.github.io/helios/reference/create_events.md)
  : Generate a list of model events with listeners

## Model

- [`run_simulation()`](https://mrc-ide.github.io/helios/reference/run_simulation.md)
  : Run the simulation
- [`run_simulations_from_table()`](https://mrc-ide.github.io/helios/reference/run_simulations_from_table.md)
  : Run helios simulations using table of parameter values

## Sampling

- [`sample_log_normal()`](https://mrc-ide.github.io/helios/reference/sample_log_normal.md)
  : Sample variables from an log-normal distribution with fixed sum
- [`sample_negbinom()`](https://mrc-ide.github.io/helios/reference/sample_negbinom.md)
  : Sample variables from a negative binomial distribution with fixed
  sum
- [`sample_offset_truncated_power_distribution()`](https://mrc-ide.github.io/helios/reference/sample_offset_truncated_power_distribution.md)
  : Sample variables from an offset truncated power distribution with
  fixed sum

## Data

- [`baseline_household_demographics_uk`](https://mrc-ide.github.io/helios/reference/baseline_household_demographics_uk.md)
  : Data from ONS 2011 on baseline household demographics from Hinch et
  al.
- [`baseline_household_demographics_usa`](https://mrc-ide.github.io/helios/reference/baseline_household_demographics_usa.md)
  : Data from RTI Synthetic population of USA containing information on
  household size and age distribution. Selected for the county of San
  Francisco.
- [`schools_uk`](https://mrc-ide.github.io/helios/reference/schools_uk.md)
  : Data on English schools from the 2022/2023 School Census
- [`schools_usa`](https://mrc-ide.github.io/helios/reference/schools_usa.md)
  : Data on US schools from 2019/2020 from the National Center for
  Education Statistics

## Intervention

- [`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md)
  : Compute per-location intervention efficacy from baseline ACH
- [`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md)
  : Wells-Riley efficacy for a single location given baseline ACH and
  delta
- [`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md)
  : Wells-Riley delta-eACH required to hit a target efficacy
- [`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md)
  : Update model parameters with intervention switches
- [`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md)
  : Generate joint intervention switches
- [`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md)
  : Generate intervention switches for a particular setting
- [`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md)
  : Construct an intervention object
- [`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md)
  : Install an intervention into the parameters list
- [`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
  : Convert UV-C parameters to equivalent ACH (eACH)

## Riskiness

- [`ach_to_p_inf()`](https://mrc-ide.github.io/helios/reference/ach_to_p_inf.md)
  : Wells-Riley infection probability per location
- [`convert_ach_to_riskiness()`](https://mrc-ide.github.io/helios/reference/convert_ach_to_riskiness.md)
  : Convert per-location ACH values to per-location riskiness
- [`generate_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/generate_setting_specific_ach.md)
  : Generate per-location baseline ACH values for a setting
- [`set_default_ach()`](https://mrc-ide.github.io/helios/reference/set_default_ach.md)
  : Set a uniform default ACH for a setting type
- [`set_setting_specific_ach()`](https://mrc-ide.github.io/helios/reference/set_setting_specific_ach.md)
  : Set ACH distribution for a setting type

## Calibration

- [`generate_beta_sweep_plot()`](https://mrc-ide.github.io/helios/reference/generate_beta_sweep_plot.md)
  : Plot sanity-check figures for a beta sweep result
- [`generate_time_varying_beta_vectors()`](https://mrc-ide.github.io/helios/reference/generate_time_varying_beta_vectors.md)
  : Expand a transmission_fraction split and a beta_community vector
  into the five setting-specific beta vectors Helios needs
- [`get_R0_from_attack_rate()`](https://mrc-ide.github.io/helios/reference/get_R0_from_attack_rate.md)
  : Back-solve R0 from a final attack rate via the final-size relation
- [`get_beta_from_R0_finalsize()`](https://mrc-ide.github.io/helios/reference/get_beta_from_R0_finalsize.md)
  : Map a target R0 (or Rt(t) series) to beta_community via final-size
  data
- [`get_sweep_result_from_source()`](https://mrc-ide.github.io/helios/reference/get_sweep_result_from_source.md)
  : Load a sweep result from a run_beta_sweep() result or a saved file
- [`run_beta_sweep()`](https://mrc-ide.github.io/helios/reference/run_beta_sweep.md)
  : Run a beta_community sweep and back-solve R0 via the final-size
  method
- [`run_one_sweep_replicate()`](https://mrc-ide.github.io/helios/reference/run_one_sweep_replicate.md)
  : Run a single simulation replicate at a fixed beta_community value

## Miscellaneous

- [`generate_betas()`](https://mrc-ide.github.io/helios/reference/generate_betas.md)
  : generate_betas
- [`get_setting_size()`](https://mrc-ide.github.io/helios/reference/get_setting_size.md)
  : get_setting_size
- [`timestep_to_day()`](https://mrc-ide.github.io/helios/reference/timestep_to_day.md)
  : timestep_to_day
