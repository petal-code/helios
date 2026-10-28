check_population_invariant <- function(parameters) {
  population_data <- generate_population_data(parameters)

  expect_in(population_data$initial_disease_states, DISEASE_STATES)
  expect_length(population_data$initial_disease_states, parameters$human_population)

  expect_in(population_data$age_classes, AGE_CLASSES)
  expect_length(population_data$age_classes, parameters$human_population)

  num_households <- length(population_data$setting_sizes$household)
  num_schools <- length(population_data$setting_sizes$school)
  num_workplaces <- length(population_data$setting_sizes$workplace)
  num_leisure <- length(population_data$setting_sizes$leisure)

  # Location ids are 1-indexed and contiguous, with 0 meaning no location.
  # Every household, workplace and leisure location has at least one member,
  # but schools may be empty.
  expect_length(population_data$initial_household_settings, parameters$human_population)
  expect_setequal(population_data$initial_household_settings, seq_len(num_households))

  expect_length(population_data$initial_school_settings, parameters$human_population)
  expect_in(population_data$initial_school_settings, 0:num_schools)

  expect_length(population_data$initial_workplace_settings, parameters$human_population)
  expect_setequal(setdiff(population_data$initial_workplace_settings, 0), seq_len(num_workplaces))

  expect_length(population_data$initial_leisure_settings, parameters$human_population)
  expect_setequal(setdiff(unlist(population_data$initial_leisure_settings), 0), seq_len(num_leisure))

  expect_length(population_data$household_specific_ach, num_households)
  expect_length(population_data$school_specific_ach, num_schools)
  expect_length(population_data$workplace_specific_ach, num_workplaces)
  expect_length(population_data$leisure_specific_ach, num_leisure)

  expect_length(population_data$household_specific_riskiness, num_households)
  expect_length(population_data$school_specific_riskiness, num_schools)
  expect_length(population_data$workplace_specific_riskiness, num_workplaces)
  expect_length(population_data$leisure_specific_riskiness, num_leisure)

  # There's a 1:1 mapping between households and individuals. That is not true
  # of other locations, eg. not everyone visits a school or a workplace.
  expect_equal(sum(population_data$setting_sizes$household), parameters$human_population)
  expect_equal(sum(population_data$setting_sizes$workplace), sum(population_data$initial_workplace_settings != 0))
  expect_equal(sum(population_data$setting_sizes$school), sum(population_data$initial_school_settings != 0))

  # Total of workplace and school does adds up to the size of the non-elderly
  # population though.
  total_activity <- sum(population_data$setting_sizes$workplace) + sum(population_data$setting_sizes$school)
  expect_equal(total_activity, sum(population_data$age_classes != "elderly"))
}

test_that("population data invariants", {
  check_population_invariant(with_default_ach(get_parameters()))
})

test_that("generate_population_data() saves the seed it was built with", {
  parameters <- with_default_ach(get_parameters(list(
    seed = 5, human_population = 1000, number_initial_S = 995
  )))
  expect_identical(generate_population_data(parameters)$seed, 5)

  # A NULL seed is replaced by a random one, which rebuilds the same population:
  parameters["seed"] <- list(NULL)
  population_data <- generate_population_data(parameters)
  expect_true(is.numeric(population_data$seed) && length(population_data$seed) == 1)
  parameters$seed <- population_data$seed
  expect_identical(generate_population_data(parameters), population_data)
})

test_that("run_simulation() gives the same result whether or not the population is provided", {
  parameters <- with_default_ach(get_parameters(list(simulation_time = 10, seed = 1)))

  expected <- run_simulation(parameters)$result
  actual <- run_simulation(parameters, population_data = generate_population_data(parameters))$result

  expect_identical(actual, expected)
})

test_that("a population can be saved to a file and reused", {
  parameters <- with_default_ach(get_parameters(list(simulation_time = 10, seed = 1)))
  population_data <- generate_population_data(parameters)

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(population_data, path)
  restored <- readRDS(path)

  expect_identical(restored, population_data)
  expect_identical(
    run_simulation(parameters, population_data = restored)$result,
    run_simulation(parameters, population_data = population_data)$result
  )
})

test_that("reusing a population gives the same result on every run", {
  parameters <- with_default_ach(get_parameters(list(simulation_time = 10, seed = 1)))
  population_data <- generate_population_data(parameters)

  expect_identical(
    run_simulation(parameters, population_data = population_data)$result,
    run_simulation(parameters, population_data = population_data)$result
  )
})
