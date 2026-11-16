small_test_parameters <- function(simulation_time) {
  parameters <- get_parameters(overrides = list(
    simulation_time = simulation_time,
    seed = 1,
    human_population = 1000,
    number_initial_S = 990,
    number_initial_E = 10
  ))
  parameters
}

test_that("run_simulation() is reproducible for a given seed", {
  parameters <- small_test_parameters(simulation_time = 5)

  first <- run_simulation(parameters)$result
  second <- run_simulation(parameters)$result

  expect_identical(first, second)
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
  # Set up example parameter table input:
  parameter_table <- data.frame("simulation_time" = c(2, 4))

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
  # Set up example parameter table input:
  parameter_table <- data.frame("simulation_time" = c(2, 4))

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

test_that("runs sharing a seed match until far UVC switches on, whatever the coverage type", {
  aqi_parameters <- function(coverage_type) {
    parameters <- small_test_parameters(simulation_time = 10)
    for (setting in c("school", "workplace", "household", "leisure")) {
      parameters <- set_setting_specific_riskiness(
        parameters,
        setting = setting,
        mean = 0,
        sd = 0.4,
        min = 0.4,
        max = 2.5
      )
    }
    set_uvc(
      parameters,
      setting = "joint",
      coverage = 0.4,
      coverage_target = "square_footage",
      coverage_type = coverage_type,
      efficacy = 0.8,
      timestep = 11
    )
  }

  random <- run_simulation(aqi_parameters("random"))$result
  targeted <- run_simulation(aqi_parameters("targeted_riskiness"))$result

  # Allocation draws from its own stream, so the runs are identical before
  # far UVC switches on at timestep 11:
  before <- random$timestep < 11
  expect_equal(random[before, ], targeted[before, ])
})

test_that("with zero efficacy, random and targeted allocation give identical runs", {
  zero_efficacy_parameters <- function(coverage_type) {
    parameters <- small_test_parameters(simulation_time = 10)
    set_uvc(
      parameters,
      setting = "joint",
      coverage = 0.4,
      coverage_target = "square_footage",
      coverage_type = coverage_type,
      efficacy = 0,
      timestep = 1
    )
  }

  # Allocation differs, but with zero efficacy it has no effect, so the whole
  # run must match when the main random stream is shared:
  expect_equal(
    run_simulation(zero_efficacy_parameters("random"))$result,
    run_simulation(zero_efficacy_parameters("targeted_riskiness"))$result
  )
})
