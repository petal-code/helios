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

  # One household near-field riskiness value too few:
  broken <- inputs
  broken$population_data$household_specific_near_field_riskiness <-
    broken$population_data$household_specific_near_field_riskiness[-1]
  expect_error(
    create_SE_from(broken),
    "household_specific_near_field_riskiness must have one value"
  )

  # Workplace far-field efficacy for one workplace fewer:
  broken <- inputs
  broken$intervention_data$far_field_efficacy$workplace <-
    broken$intervention_data$far_field_efficacy$workplace[-1]
  expect_error(create_SE_from(broken), "far_field_efficacy\\$workplace must have one value")

  # No workplace near-field efficacy:
  broken <- inputs
  broken$intervention_data$near_field_efficacy$workplace <- NULL
  expect_error(create_SE_from(broken), "near_field_efficacy\\$workplace must have one value")
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

test_that("effective_infectious_count() counts each location's infectious, or sums their weights", {
  # Individuals 1, 2, 4 and 5 are infectious. Two of them are in location 1, one in location 3 and
  # one has no location. Nobody is in location 4.
  location <- c(1, 1, 2, 0, 3, 1)
  infectious <- c(1, 2, 4, 5)
  weight <- c(0.5, 0.2, 0.9, 0.3)
  count <- effective_infectious_count(location, infectious, 4)
  expect_identical(count, tabulate(location[infectious], 4))
  expect_identical(count, c(2L, 0L, 1L, 0L))
  expect_equal(
    effective_infectious_count(location, infectious, 4, weight = weight), c(0.7, 0, 0.3, 0)
  )
  expect_equal(
    effective_infectious_count(location, infectious, 4, weight = rep(1, 4)), c(2, 0, 1, 0)
  )

  # Nobody infectious:
  expect_identical(effective_infectious_count(location, integer(0), 4), integer(4))
  expect_identical(
    effective_infectious_count(location, integer(0), 4, weight = numeric(0)), numeric(4)
  )

  # A single location that contains everyone:
  expect_identical(effective_infectious_count(NULL, infectious, 1), 4L)
  expect_equal(effective_infectious_count(NULL, infectious, 1, weight = weight), 1.9)

  expect_error(
    effective_infectious_count(location, infectious, 4, weight = c(0.5, 0.2)),
    "weight must have one value for each infectious individual"
  )
})

test_that("the community FOI is beta_community * n_I / N, whatever its near-field fraction", {
  inputs <- small_SE_inputs()
  inputs$parameters_list$render_diagnostics <- TRUE
  inputs$population_data$initial_disease_states[1:30] <- "I_mild"
  for (near_field_fraction in c(0, 0.4)) {
    inputs$parameters_list$near_field_fraction_community <- near_field_fraction
    renderer <- individual::Render$new(1)
    process <- create_SE_process(
      variables_list = create_variables(inputs$parameters_list, inputs$population_data),
      events_list = list(),
      parameters_list = inputs$parameters_list,
      population_data = inputs$population_data,
      intervention_data = inputs$intervention_data,
      renderer = renderer
    )
    process(1)
    expect_equal(renderer$to_dataframe()$FOI_community, 0.2 * 30 / 1000)
  }

  # At the default near-field fraction of 0, exactly as before the community was a setting:
  expect_identical(setting_riskiness(list(), list(), "community", 1, 0), 1)
  expect_identical(location_FOI(NULL, 1:30, 1, 0.2, 1000), 0.2 * 30 / 1000)
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

  # Without a near-field share, the riskiness is the far-field riskiness
  for (setting in c("workplace", "school", "leisure")) {
    riskiness <- population_data[[paste0(setting, "_specific_far_field_riskiness")]]
    efficacy <- intervention_data$far_field_efficacy[[setting]]
    expect_identical(
      setting_riskiness(population_data, intervention_data, setting, 3, 0),
      riskiness
    )
    expect_identical(
      setting_riskiness(population_data, intervention_data, setting, 4, 0),
      riskiness * (1 - efficacy)
    )
  }
  # A joint intervention doesn't cover households:
  expect_identical(
    setting_riskiness(population_data, intervention_data, "household", 4, 0),
    population_data$household_specific_far_field_riskiness
  )
})

test_that("the FOI from a setting combines its far-field and near-field transmission", {
  # Two schools, with an intervention from timestep 2 that reduces both fields' riskiness
  population_data <- list(
    school_specific_far_field_riskiness = c(2, 0.5),
    school_specific_near_field_riskiness = c(1, 3)
  )
  intervention_data <- list(
    far_field_efficacy = list(school = c(0.5, 0.2)),
    near_field_efficacy = list(school = c(0.25, 0)),
    timestep = list(school = 2)
  )

  # A quarter of transmission is near-field. Before the intervention, school 1's riskiness is
  # 0.75 * 2 + 0.25 * 1, and school 2's 0.75 * 0.5 + 0.25 * 3:
  expect_equal(
    setting_riskiness(population_data, intervention_data, "school", 2, 0.25),
    c(1.75, 1.125)
  )
  # After it, they're 0.75 * 2 * 0.5 + 0.25 * 1 * 0.75 and 0.75 * 0.5 * 0.8 + 0.25 * 3 * 1:
  riskiness <- setting_riskiness(population_data, intervention_data, "school", 3, 0.25)
  expect_equal(riskiness, c(0.9375, 1.05))

  # School 1 has two pupils, one of them infectious, and school 2 three, two of them infectious.
  # The sixth individual has no school.
  FOI <- location_FOI(
    location = c(1, 1, 2, 2, 2, 0), infectious = c(1, 3, 4), riskiness = riskiness, beta = 0.4,
    size = c(2, 3)
  )
  expect_equal(FOI, c(0.9375 * 0.4 / 2, 0.9375 * 0.4 / 2, rep(1.05 * 0.4 * 2 / 3, 3), 0))
})
