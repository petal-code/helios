#====================================#
#===== generate_population_data =====#
#====================================#

test_that("generate_population_data errors if parameter list does not contain seed parameter", {
  # Establish the list of model parameters:
  parameters_list <- get_parameters()

  # Remove the seed parameter:
  parameters_list$seed <- NULL

  # Check that generate_population_data() errors when seed not in the parameters list:
  expect_error(
    object = generate_population_data(parameters_list = parameters_list),
    regexp = "parameters list must contain a variable called seed"
  )
})

test_that("generate_population_data generates the same population for the same seed", {
  # Establish the list of model parameters with a fixed seed:
  parameters_list <- with_default_ach(get_parameters(overrides = list(seed = 123)))

  # Generate the population twice:
  first <- generate_population_data(parameters_list = parameters_list)
  second <- generate_population_data(parameters_list = parameters_list)

  expect_identical(first, second)
})

test_that("population generators continue the random stream rather than reseeding", {
  # Establish the list of model parameters with a fixed seed:
  parameters_list <- get_parameters(overrides = list(seed = 123))

  # Two consecutive draws should differ. If the generator reset the seed from
  # parameters_list$seed, they would be identical:
  set.seed(1)
  first <- generate_initial_disease_states(parameters_list = parameters_list)
  second <- generate_initial_disease_states(parameters_list = parameters_list)
  expect_false(identical(first, second))
})

#===========================================#
#===== generate_initial_disease_states =====#
#===========================================#

test_that("generate_initial_disease_states errors if parameter list does not contain number_initial_E parameter", {
  # Establish the list of model parameters:
  parameters_list <- get_parameters()

  # Remove the number_initial_E parameter:
  parameters_list$number_initial_E <- NULL

  # Check that generate_initial_disease_states() errors when number_initial_E not in the parameters
  # list:
  expect_error(
    object = generate_initial_disease_states(parameters_list = parameters_list),
    regexp = "parameters list must contain a variable called number_initial_E"
  )
})

test_that("generate_initial_disease_states errors if parameter list does not contain human_population parameter", {
  # Establish the list of model parameters:
  parameters_list <- get_parameters()

  # Remove the number_initially_exposed parameter:
  parameters_list$human_population <- NULL

  # Check that generate_initial_disease_states() errors when number_initially_exposed not in the parameters
  # list:
  expect_error(
    object = generate_initial_disease_states(parameters_list = parameters_list),
    regexp = "parameters list must contain a variable called human_population"
  )
})

test_that("generate_initial_disease_states returns the expected disease states", {
  # Establish the list of model parameters:
  parameters_list <- get_parameters(
    overrides = list(number_initial_S = 9953, number_initial_E = 47)
  )

  # Generate the initial disease states:
  initial_disease_states <- generate_initial_disease_states(
    parameters_list = parameters_list
  )

  # Check that the number of exposed individuals matches expectation:
  expect_equal(
    object = sum(initial_disease_states == "E"),
    parameters_list$number_initial_E
  )

  # Check that the number of susceptible indiivduals matches expectation:
  expect_equal(
    sum(initial_disease_states == "S"),
    parameters_list$number_initial_S
  )
})

test_that("generate_initial_disease_states returns vector containing only susceptible and exposed individuals", {
  # Establish list of model parameters:
  parameters_list <- get_parameters()

  # Generate the initial disease states:
  initial_disease_states <- generate_initial_disease_states(
    parameters_list = parameters_list
  )

  # Generate a vector of the disease states:
  disease_states <- c("S", "E")

  # Check that the initial disease states are all recognised disease states
  expect_contains(initial_disease_states, disease_states)
})

#====================================#
#===== generate_initial_schools =====#
#====================================#

test_that("generate_initial_schools errors if parameter_list does not contain human_population", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove human_population from the parameters list:
  parameters_list$human_population <- NULL

  # Check that the generate_initial_schools() function errors due to missing human_population parameter:
  expect_error(
    object = generate_initial_schools(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes
    ),
    regexp = "parameters list must contain a variable called human_population"
  )
})

test_that("generate_initial_schools errors if parameter_list does not contain school_student_staff_ratio", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove school_student_staff_ratio from the parameters list:
  parameters_list$school_student_staff_ratio <- NULL

  # Check that the generate_initial_schools() function errors due to missing school_student_staff_ratio parameter:
  expect_error(
    object = generate_initial_schools(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes
    ),
    regexp = "parameters list must contain a variable called school_student_staff_ratio"
  )
})

test_that("generate_initial_schools returns a vector equal in length to the number of people simulated and assigns some zeroes", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Generate the vector of initial schools:
  initial_schools <- generate_initial_schools(
    parameters_list = parameters_list,
    initial_age_classes = population_data$age_classes
  )

  # Check that the schools object has entries for each individual in the population:
  expect_length(object = initial_schools, n = parameters_list$human_population)

  # Check that the schools object contains a non-zero number of "0" (no school) entries:
  expect_gt(object = sum(initial_schools == "0"), 0)
})

test_that("generate_initial_schools assigns at least one adult to each school", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Generate the vector of initial schools:
  initial_schools <- generate_initial_schools(
    parameters_list = parameters_list,
    initial_age_classes = population_data$age_classes
  )

  # Get the indices of all adults in the population:
  adult_age_class_indices <- which(population_data$age_classes == "adult")
  elderly_age_class_indices <- which(population_data$age_classes == "elderly")

  # Check that all schools have at least one adult assigned to them:
  expect_true(all(
    table(as.numeric(initial_schools[adult_age_class_indices])) > 0
  ))

  # Ensure that no elderly individuals are assigned schools
  expect_equal(object = sum(initial_schools[elderly_age_class_indices] > 0), 0)
})

test_that("generate_initial_schools assigns no elderly individuals to any school", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Generate the vector of initial schools:
  initial_schools <- generate_initial_schools(
    parameters_list = parameters_list,
    initial_age_classes = population_data$age_classes
  )

  # Get the indices of all elderly individuals in the population:
  elderly_age_class_indices <- which(population_data$age_classes == "elderly")

  # Check that all schools have no elderly individuals assigned to them:
  expect_identical(
    object = sum(as.numeric(initial_schools[elderly_age_class_indices])),
    0
  )
})

#=======================================#
#===== generate_initial_workplaces =====#
#=======================================#

test_that("generate_initial_workplaces errors if parameter_list does not contain human_population", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove human_population from the parameters list:
  parameters_list$human_population <- NULL

  # Check that the generate_initial_schools() function errors due to missing human_population parameter:
  expect_error(
    object = generate_initial_workplaces(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes,
      initial_school_settings = population_data$initial_school_settings
    ),
    regexp = "parameters list must contain a variable called human_population"
  )
})

test_that("generate_initial_workplaces errors if parameter_list does not contain workplace_prop_max", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove workplace_prop_max from the parameters list:
  parameters_list$workplace_prop_max <- NULL

  # Check that the generate_initial_schools() function errors due to missing workplace_prop_max parameter:
  expect_error(
    object = generate_initial_workplaces(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes,
      initial_school_settings = population_data$initial_school_settings
    ),
    regexp = "parameters list must contain a variable called workplace_prop_max"
  )
})

test_that("generate_initial_workplaces errors if parameter_list does not contain workplace_a", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove workplace_a from the parameters list:
  parameters_list$workplace_a <- NULL

  # Check that the generate_initial_schools() function errors due to missing workplace_a parameter:
  expect_error(
    object = generate_initial_workplaces(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes,
      initial_school_settings = population_data$initial_school_settings
    ),
    regexp = "parameters list must contain a variable called workplace_a"
  )
})

test_that("generate_initial_workplaces errors if parameter_list does not contain workplace_c", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove workplace_c from the parameters list:
  parameters_list$workplace_c <- NULL

  # Check that the generate_initial_schools() function errors due to missing workplace_c parameter:
  expect_error(
    object = generate_initial_workplaces(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes,
      initial_school_settings = population_data$initial_school_settings
    ),
    regexp = "parameters list must contain a variable called workplace_c"
  )
})

#====================================#
#===== generate_initial_leisure =====#
#====================================#

#=======================================#
#===== generate_initial_households =====#
#=======================================#
