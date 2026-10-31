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

  # A workplace near-field efficacy above 1:
  broken <- inputs
  broken$intervention_data$near_field_efficacy$workplace[1] <- 1.5
  expect_error(
    create_SE_from(broken),
    "near_field_efficacy\\$workplace must be in \\[0, 1\\] for every location"
  )
})

#============================#
#===== FOI calculations =====#
#============================#

test_that("setting_FOI() shares each location's infectious individuals among its members", {
  # Location 1 has two members, one of them infectious, location 2 has one member and location 3
  # none. The fourth individual has no location.
  fields <- list(
    far_field = list(riskiness = c(2, 1, 1), efficacy = NULL),
    near_field = list(riskiness = c(1, 1, 1), efficacy = NULL)
  )
  FOI <- setting_FOI(
    location = c(1, 1, 2, 0), infectious = 1, fields = fields, beta = 0.5, size = c(2, 1, 0),
    near_field_fraction = 0
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
  fields <- setting_fields(list(), list(), "community", 1)
  expect_identical(fields$far_field, list(riskiness = 1, efficacy = NULL))
  expect_identical(fields$near_field, list(riskiness = 1, efficacy = NULL))
  expect_identical(setting_FOI(NULL, 1:30, fields, 0.2, 1000, 0), 0.2 * 30 / 1000)
})

test_that("setting_fields() applies a joint intervention after its timestep", {
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

  # Each field's riskiness, and its efficacy only after the intervention's timestep
  for (setting in c("workplace", "school", "leisure")) {
    for (field in c("far_field", "near_field")) {
      riskiness <- population_data[[paste0(setting, "_specific_", field, "_riskiness")]]
      efficacy <- intervention_data[[paste0(field, "_efficacy")]][[setting]]
      expect_identical(
        setting_fields(population_data, intervention_data, setting, 3)[[field]],
        list(riskiness = riskiness, efficacy = NULL)
      )
      expect_identical(
        setting_fields(population_data, intervention_data, setting, 4)[[field]],
        list(riskiness = riskiness, efficacy = efficacy)
      )
    }
  }
  # A joint intervention doesn't cover households:
  household <- setting_fields(population_data, intervention_data, "household", 4)
  expect_null(household$far_field$efficacy)
  expect_null(household$near_field$efficacy)
})

# Two schools, with an intervention from timestep 2 that reduces transmission in both fields.
# School 1 has two pupils, one of them infectious, and school 2 three, two of them infectious. The
# sixth individual has no school. A quarter of transmission is near-field.
two_schools_FOI <- function(t, weight = list(), protection = list()) {
  population_data <- list(
    school_specific_far_field_riskiness = c(2, 0.5),
    school_specific_near_field_riskiness = c(1, 3)
  )
  intervention_data <- list(
    far_field_efficacy = list(school = c(0.5, 0.2)),
    near_field_efficacy = list(school = c(0.25, 0)),
    timestep = list(school = 2)
  )
  setting_FOI(
    location = c(1, 1, 2, 2, 2, 0),
    infectious = c(1, 3, 4),
    fields = setting_fields(population_data, intervention_data, "school", t),
    beta = 0.4,
    size = c(2, 3),
    near_field_fraction = 0.25,
    weight = weight,
    protection = protection
  )
}

test_that("the FOI from a setting combines its far-field and near-field transmission", {
  # Before the intervention, school 1's riskiness is 0.75 * 2 + 0.25 * 1, and school 2's
  # 0.75 * 0.5 + 0.25 * 3:
  expect_equal(two_schools_FOI(2), c(rep(1.75 * 0.4 / 2, 2), rep(1.125 * 0.4 * 2 / 3, 3), 0))
  # After it, they're 0.75 * 2 * 0.5 + 0.25 * 1 * 0.75 and 0.75 * 0.5 * 0.8 + 0.25 * 3 * 1:
  expect_equal(two_schools_FOI(3), c(rep(0.9375 * 0.4 / 2, 2), rep(1.05 * 0.4 * 2 / 3, 3), 0))
})

test_that("the FOI from a setting combines each individual's protection with the location's", {
  # The infectious individuals' weights make the effective infectious count 1 in both schools in
  # the far field, and 0.2 in school 1 and 0.2 + 1 in school 2 in the near field
  weight <- list(far_field = c(1, 0.5, 0.5), near_field = c(0.2, 0.2, 1))
  # After the intervention, the far-field FOI on school 1's pupils is 0.75 * 0.4 * 2 * 0.5 * 1 / 2,
  # and on school 2's 0.75 * 0.4 * 0.5 * 0.8 * 1 / 3, before their own protection. The near-field
  # FOI is 0.25 * 0.4 * 1 * 0.75 * 0.2 / 2 and 0.25 * 0.4 * 3 * 1 * 1.2 / 3.
  far <- c(0.15, 0.04)
  near <- c(0.0075, 0.12)
  expect_equal(two_schools_FOI(3, weight), c(rep(far[1] + near[1], 2), rep(far[2] + near[2], 3), 0))

  # Individuals 2, 4, 5 and 6 protect themselves, with an efficacy of 0.5 in the far field and 0.4
  # in the near field. Individual 6 has no school, so it changes nothing for them.
  protected <- c(FALSE, TRUE, FALSE, TRUE, TRUE, TRUE)
  far_protection <- ifelse(protected, 0.5, 0)
  near_protection <- ifelse(protected, 0.4, 0)
  expect_equal(
    two_schools_FOI(3, weight, list(far_field = far_protection, near_field = near_protection)),
    c(
      far[1] + near[1], far[1] * 0.5 + near[1] * 0.6,
      far[2] + near[2], rep(far[2] * 0.5 + near[2] * 0.6, 2),
      0
    )
  )
  # With protection in the far field only:
  expect_equal(
    two_schools_FOI(3, weight, list(far_field = far_protection)),
    c(
      far[1] + near[1], far[1] * 0.5 + near[1],
      far[2] + near[2], rep(far[2] * 0.5 + near[2], 2),
      0
    )
  )
  # Before the intervention there's no location efficacy to combine with. Without weights, the
  # far-field FOI is 0.75 * 0.4 * 2 * 1 / 2 and 0.75 * 0.4 * 0.5 * 2 / 3, and the near-field FOI
  # 0.25 * 0.4 * 1 * 1 / 2 and 0.25 * 0.4 * 3 * 2 / 3.
  far_before <- c(0.3, 0.1)
  near_before <- c(0.05, 0.2)
  expect_equal(
    two_schools_FOI(2, protection = list(far_field = far_protection, near_field = near_protection)),
    c(
      far_before[1] + near_before[1], far_before[1] * 0.5 + near_before[1] * 0.6,
      far_before[2] + near_before[2], rep(far_before[2] * 0.5 + near_before[2] * 0.6, 2),
      0
    )
  )
  # Protection of 0 gives the FOI without protection:
  no_protection <- list(far_field = rep(0, 6), near_field = rep(0, 6))
  expect_equal(two_schools_FOI(3, weight, no_protection), two_schools_FOI(3, weight))
})

test_that("each individual's protection applies to the community's single FOI", {
  fields <- setting_fields(list(), list(), "community", 1)
  # Three of four individuals are infectious. The near-field fraction makes no difference.
  for (near_field_fraction in c(0, 0.3)) {
    FOI <- setting_FOI(
      NULL, 1:3, fields, 0.2, 4, near_field_fraction,
      protection = list(far_field = c(0, 0.5, 1, 0), near_field = c(0, 0.5, 1, 0))
    )
    expect_equal(FOI, 0.2 * 3 / 4 * c(1, 0.5, 0, 1))
  }
})

test_that("combine_protection() multiplies what the location and the individual let through", {
  expect_equal(combine_protection(c(0, 0.5, 0.2, 1), c(0.5, 0.5, 0, 0.3)), c(0.5, 0.25, 0.8, 0))
  expect_identical(combine_protection(0, c(0, 0.4)), c(1, 0.6))
})
