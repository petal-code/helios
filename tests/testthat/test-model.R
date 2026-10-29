small_test_parameters <- function(simulation_time) {
  parameters <- get_parameters(overrides = list(
    simulation_time = simulation_time,
    seed = 1,
    human_population = 1000,
    number_initial_S = 990,
    number_initial_E = 10
  ))
  for (setting in c("household", "workplace", "school", "leisure")) {
    parameters <- set_default_ach(parameters, setting, 4)
  }
  parameters
}

# Random coverage and variation both draw random numbers before the simulation
# starts, so this exercises the whole random stream:
with_random_workplace_intervention <- function(parameters) {
  set_intervention_ach(
    parameters,
    setting = "workplace",
    coverage_target = "individuals",
    coverage_type = "random",
    timestep = 1,
    intervention = make_intervention(
      name = "constant_delta",
      delta_function = function(delta) delta,
      delta_params = list(delta = 5),
      variation = TRUE,
      variation_params = list(sdlog = 0.5),
      coverage = 0.5
    )
  )
}

test_that("run_simulation() is reproducible for a given seed", {
  parameters <- small_test_parameters(simulation_time = 5)

  first <- run_simulation(parameters)$result
  second <- run_simulation(parameters)$result

  expect_identical(first, second)
})

test_that("run_simulation() gives the pinned result for a fixed seed", {
  # These numbers change whenever the random stream changes, which changes
  # every seeded run, so update them only on purpose. They match #167, where
  # the population, the intervention and the simulation drew from one stream.
  parameters <- with_random_workplace_intervention(small_test_parameters(simulation_time = 15))
  parameters$number_initial_S <- 970
  parameters$number_initial_E <- 30
  result <- run_simulation(parameters)$result

  final <- result[nrow(result), c("S_count", "E_count", "I_mild_count", "I_hosp_count", "R_count", "D_count")]
  expect_equal(
    unlist(final),
    c(S_count = 438, E_count = 240, I_mild_count = 207, I_hosp_count = 6, R_count = 108, D_count = 1)
  )
  expect_equal(
    result$E_new,
    c(0, 0, 0, 1, 2, 6, 9, 6, 18, 12, 4, 9, 13, 15, 14, 26, 24, 22, 24, 32, 31, 29, 34, 30, 27, 41, 29, 41, 33, 36)
  )
})

test_that("generate_intervention_data() does not depend on earlier random draws", {
  parameters <- with_random_workplace_intervention(small_test_parameters(simulation_time = 5))
  population_data <- generate_population_data(parameters)

  set.seed(10)
  first <- generate_intervention_data(parameters, population_data)
  set.seed(20)
  stats::runif(5)
  second <- generate_intervention_data(parameters, population_data)
  expect_identical(first, second)

  # The same holds when the run's seed differs from the population's:
  parameters$seed <- 2
  set.seed(10)
  first <- generate_intervention_data(parameters, population_data)
  set.seed(20)
  second <- generate_intervention_data(parameters, population_data)
  expect_identical(first, second)
})

test_that("run_simulation() resumed from a saved state matches an uninterrupted run", {
  parameters <- small_test_parameters(simulation_time = 6)
  full <- run_simulation(parameters)$result

  parameters$simulation_time <- 3
  part_one <- run_simulation(parameters)
  part_two <- run_simulation(parameters, state = part_one$state)

  expect_equal(part_two$result$timestep, (3 / parameters$dt + 1):(6 / parameters$dt))
  resumed <- rbind(part_one$result, part_two$result)
  expect_equal(resumed, full)
})

test_that("run_simulation() resumed in several segments, splitting a day, matches an uninterrupted run", {
  parameters <- small_test_parameters(simulation_time = 6)
  full <- run_simulation(parameters)$result

  segments <- list()
  state <- NULL
  for (simulation_time in c(1, 2.5, 2.5)) {
    parameters$simulation_time <- simulation_time
    run <- run_simulation(parameters, state = state)
    segments[[length(segments) + 1]] <- run$result
    state <- run$state
  }

  expect_equal(do.call(rbind, segments), full)
})

test_that("run_simulation() with seed = NULL saves the seed it drew and can be resumed", {
  parameters <- small_test_parameters(simulation_time = 3)
  parameters["seed"] <- list(NULL)
  part_one <- run_simulation(parameters)
  part_two <- run_simulation(parameters, state = part_one$state)

  expect_true(is.numeric(part_one$state$seed) && length(part_one$state$seed) == 1)
  expect_identical(part_two$state$seed, part_one$state$seed)

  # The drawn seed reproduces the run when passed explicitly:
  parameters$seed <- part_one$state$seed
  parameters$simulation_time <- 6
  full <- run_simulation(parameters)$result
  expect_equal(rbind(part_one$result, part_two$result), full)
})

test_that("run_simulation() errors when resuming with a different seed", {
  parameters <- small_test_parameters(simulation_time = 3)
  part_one <- run_simulation(parameters)

  parameters$seed <- 2
  expect_error(
    run_simulation(parameters, state = part_one$state),
    regexp = "differs from the seed of the saved run"
  )
})

test_that("run_simulation() resumed with a population built from another seed matches an uninterrupted run", {
  # Random coverage depends on the run's seed, so a resume must reuse it as
  # well as the population:
  parameters <- with_random_workplace_intervention(small_test_parameters(simulation_time = 6))
  population_data <- generate_population_data(modifyList(parameters, list(seed = 2)))
  full <- run_simulation(parameters, population_data = population_data)$result

  parameters$simulation_time <- 3
  part_one <- run_simulation(parameters, population_data = population_data)
  expect_identical(part_one$state$seed, 1)
  expect_identical(part_one$state$population_seed, 2)

  # The population can be passed in again, or rebuilt from the saved seed:
  passed_again <- run_simulation(parameters, population_data = population_data, state = part_one$state)
  rebuilt <- run_simulation(parameters, state = part_one$state)
  expect_equal(rbind(part_one$result, passed_again$result), full)
  expect_equal(rbind(part_one$result, rebuilt$result), full)
})

test_that("run_simulation() resumes a run with seed = NULL on a population generated with seed = NULL", {
  parameters <- small_test_parameters(simulation_time = 3)
  parameters["seed"] <- list(NULL)
  population_data <- generate_population_data(parameters)
  part_one <- run_simulation(parameters, population_data = population_data)
  expect_identical(part_one$state$population_seed, population_data$seed)

  # Without the population, the resume rebuilds it from the saved seed:
  passed_again <- run_simulation(parameters, population_data = population_data, state = part_one$state)
  rebuilt <- run_simulation(parameters, state = part_one$state)
  expect_identical(rebuilt$result, passed_again$result)
})

test_that("run_simulation() errors when resuming with a different population", {
  parameters <- small_test_parameters(simulation_time = 3)
  part_one <- run_simulation(parameters)

  other_population <- generate_population_data(modifyList(parameters, list(seed = 2)))
  expect_error(
    run_simulation(parameters, population_data = other_population, state = part_one$state),
    regexp = "population_data was built with seed 2, but the saved run used a population built with seed 1"
  )
})

test_that("run_simulation() errors on a malformed state or a resume of less than one timestep", {
  parameters <- small_test_parameters(simulation_time = 1)
  part_one <- run_simulation(parameters)

  expect_error(
    run_simulation(parameters, state = part_one$state$individual),
    regexp = "state must be the state element returned by run_simulation()"
  )

  parameters$simulation_time <- 0
  expect_error(
    run_simulation(parameters, state = part_one$state),
    regexp = "simulation_time must cover at least one timestep"
  )
})

with_time_varying_betas <- function(parameters, days) {
  parameters$time_varying_transmission_on <- TRUE
  for (beta in c("beta_household", "beta_workplace", "beta_school", "beta_leisure", "beta_community")) {
    parameters[[beta]] <- parameters[[beta]] * seq(0.5, 1.5, length.out = days)
  }
  parameters
}

test_that("run_simulation() resumed with time-varying transmission matches an uninterrupted run", {
  parameters <- with_time_varying_betas(small_test_parameters(simulation_time = 6), days = 6)
  full <- run_simulation(parameters)$result

  parameters$simulation_time <- 3
  part_one <- run_simulation(parameters)
  part_two <- run_simulation(parameters, state = part_one$state)

  resumed <- rbind(part_one$result, part_two$result)
  expect_equal(resumed, full)
})

test_that("run_simulation() errors when time-varying betas don't cover the resumed run", {
  parameters <- with_time_varying_betas(small_test_parameters(simulation_time = 3), days = 3)
  part_one <- run_simulation(parameters)

  expect_error(
    run_simulation(parameters, state = part_one$state),
    regexp = "must have a value for every day up to day 6"
  )
})

test_that("run_simulations_from_table() errors when the parameter_table input contains unrecognised column names", {
  # Set up example parameter table input:
  parameter_table <- data.frame(
    "simulation_time" = c(100, 100),
    "gar_uvc" = c("TRUE", "FALSE")
  )

  expect_error(
    object = run_simulations_from_table(
      parameters_table = parameter_table,
      output_type = "both"
    ),
    regexp = "Error: Parameter name in parameter_table not a recognised helios parameter"
  )
})

test_that("run_simulations_from_table() errors when the parameter_table input is not a data frame", {
  # Set up example parameter table input:
  parameter_table <- numeric(length = 10)

  expect_error(
    object = run_simulations_from_table(
      parameters_table = parameter_table,
      output_type = "both"
    ),
    regexp = "Error: parameters_table is not a data.frame - please reformat"
  )
})

test_that("run_simulations_from_table() run_simulations_from_table() returns list of parameters when output_type set to parameters", {
  # Generate a basic list of parameters with only the simulation time amended:
  parameter_list <- get_parameters(
    overrides = list(
      simulation_time = 10
    )
  )

  # Set up example parameter table input:
  parameter_table <- data.frame("simulation_time" = c(10))

  # Run the function using the parameters setting:
  simulation_output <- run_simulations_from_table(
    parameters_table = parameter_table,
    output_type = "parameters"
  )

  # Check that the run_simulations_from_table() function returns an identical parameter:
  expect_identical(object = simulation_output[[1]], expected = parameter_list)
})

test_that("run_simulations_from_table() run_simulations_from_table() returns list of parameters when output_type set to simulations", {
  # Set up example parameter table input. default_ach_* columns are required
  # because get_parameters() no longer defaults ACH silently:
  parameter_table <- data.frame(
    "simulation_time"        = c(2, 4),
    "default_ach_household"  = c(4, 4),
    "default_ach_workplace"  = c(4, 4),
    "default_ach_school"     = c(4, 4),
    "default_ach_leisure"    = c(4, 4)
  )

  # Run the function using the parameters setting:
  simulation_output <- run_simulations_from_table(
    parameters_table = parameter_table,
    output_type = "simulations"
  )

  # Check that the run_simulations_from_table() function returns data.frame(s) when output type is set to simulations:
  expect_true(is.data.frame(simulation_output[[1]]))

  # Check that the length of the output matches the number of rows in the parameter table
  expect_length(object = simulation_output, n = nrow(parameter_table))
})

test_that("run_simulations_from_table() run_simulations_from_table() returns list of parameters and simulation outputs when output_type set to both", {
  # Set up example parameter table input. default_ach_* columns are required
  # because get_parameters() no longer defaults ACH silently:
  parameter_table <- data.frame(
    "simulation_time"        = c(2, 4),
    "default_ach_household"  = c(4, 4),
    "default_ach_workplace"  = c(4, 4),
    "default_ach_school"     = c(4, 4),
    "default_ach_leisure"    = c(4, 4)
  )

  # Run the function using the parameters setting:
  simulation_output <- run_simulations_from_table(
    parameters_table = parameter_table,
    output_type = "both"
  )

  # Check that the output contains both parameter lists and data.frames:
  expect_length(object = simulation_output, n = 2)

  # Check that the run_simulations_from_table() function returns lists of parametres and data.frame(s)
  # when output type is set to both:
  expect_true(is.list(simulation_output[[1]][[1]]))
  expect_true(is.data.frame(simulation_output[[2]][[1]]))

  # Check that the length of the output matches the number of rows in the parameter table
  expect_length(object = simulation_output[[1]], n = nrow(parameter_table))
})
