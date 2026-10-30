#===============================#
#===== create_SE_process() =====#
#===============================#

# A small population with an intervention in workplaces, so that its efficacy is checked too
small_SE_inputs <- function() {
  parameters_list <- with_default_ach(get_parameters(overrides = list(
    human_population = 1000,
    number_initial_S = 990,
    number_initial_E = 10,
    seed = 1
  )))
  parameters_list <- set_intervention_ach(
    parameters_list,
    setting = "workplace",
    coverage_target = "individuals",
    coverage_type = "random",
    timestep = 1,
    intervention = make_intervention(
      name = "constant_delta",
      delta_function = function(delta) delta,
      delta_params = list(delta = 5),
      coverage = 0.5
    )
  )
  population_data <- generate_population_data(parameters_list)
  list(
    parameters_list = parameters_list,
    population_data = population_data,
    intervention_data = generate_intervention_data(parameters_list, population_data)
  )
}

create_SE_from <- function(inputs) {
  create_SE_process(
    variables_list = create_variables(inputs$parameters_list, inputs$population_data),
    events_list = list(),
    parameters_list = inputs$parameters_list,
    population_data = inputs$population_data,
    intervention_data = inputs$intervention_data,
    renderer = individual::Render$new(1)
  )
}

test_that("create_SE_process() accepts a generated population", {
  expect_no_error(create_SE_from(small_SE_inputs()))
})

test_that("create_SE_process() refuses settings that don't agree with each other", {
  inputs <- small_SE_inputs()

  # Someone without a household:
  broken <- inputs
  broken$population_data$initial_household_settings[1] <- 0L
  expect_error(create_SE_from(broken), "initial_household_settings must have an id from 1")

  # A workplace size that doesn't match the workplace's members:
  broken <- inputs
  broken$population_data$setting_sizes$workplace[1] <- broken$population_data$setting_sizes$workplace[1] + 1L
  expect_error(create_SE_from(broken), "setting_sizes\\$workplace must be the number of individuals")

  # One school riskiness value too many:
  broken <- inputs
  broken$population_data$school_specific_far_field_riskiness <- c(
    broken$population_data$school_specific_far_field_riskiness, 1
  )
  expect_error(create_SE_from(broken), "school_specific_far_field_riskiness must have one value")

  # A leisure location that doesn't exist:
  broken <- inputs
  num_leisure <- length(broken$population_data$setting_sizes$leisure)
  broken$population_data$initial_leisure_settings[[1]][1] <- num_leisure + 1L
  expect_error(create_SE_from(broken), "initial_leisure_settings must have ids from 0")

  # Workplace efficacy for one workplace fewer:
  broken <- inputs
  broken$intervention_data$efficacy$workplace <- broken$intervention_data$efficacy$workplace[-1]
  expect_error(create_SE_from(broken), "efficacy\\$workplace must have one value")
})

#============================#
#===== FOI calculations =====#
#============================#

test_that("location_FOI() shares each location's infectious individuals among its members", {
  # Location 1 has two members, one of them infectious, location 2 has one member and location 3
  # none. The fourth individual has no location.
  FOI <- location_FOI(
    location = c(1, 1, 2, 0), infectious = 1, riskiness = c(2, 1, 1), beta = 0.5, size = c(2, 1, 0)
  )
  expect_identical(FOI, c(0.5, 0.5, 0, 0))
})

test_that("setting_riskiness() applies a joint intervention after its timestep", {
  parameters_list <- with_default_ach(get_parameters(overrides = list(
    human_population = 1000,
    number_initial_S = 990,
    number_initial_E = 10,
    seed = 1
  )))
  parameters_list <- set_intervention_ach(
    parameters_list,
    setting = "joint",
    coverage_target = "individuals",
    coverage_type = "targeted_riskiness",
    timestep = 3,
    intervention = make_intervention(
      name = "constant_delta",
      delta_function = function(delta) delta,
      delta_params = list(delta = 5),
      coverage = 1
    )
  )
  population_data <- generate_population_data(parameters_list)
  intervention_data <- generate_intervention_data(parameters_list, population_data)

  for (setting in c("workplace", "school", "leisure")) {
    riskiness <- population_data[[paste0(setting, "_specific_far_field_riskiness")]]
    efficacy <- intervention_data$efficacy[[setting]]
    expect_identical(setting_riskiness(population_data, intervention_data, setting, 3), riskiness)
    expect_identical(setting_riskiness(population_data, intervention_data, setting, 4), riskiness * (1 - efficacy))
  }
  # A joint intervention doesn't cover households:
  expect_identical(
    setting_riskiness(population_data, intervention_data, "household", 4),
    population_data$household_specific_far_field_riskiness
  )
})
