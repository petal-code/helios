#============================#
#===== create_variables =====#
#============================#

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

test_that("generate_initial_disease_states errors if parameter list does not contain seed parameter", {
  # Establish the list of model parameters:
  parameters_list <- get_parameters()

  # Remove the number_initially_exposed parameter:
  parameters_list$seed <- NULL

  # Check that generate_initial_disease_states() errors when number_initially_exposed not in the parameters
  # list:
  expect_error(
    object = generate_initial_disease_states(parameters_list = parameters_list),
    regexp = "parameters list must contain a variable called seed"
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

test_that("generate_initial_schools errors if parameter_list does not contain seed", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove seed from the parameters list:
  parameters_list$seed <- NULL

  # Check that the generate_initial_schools() function errors due to missing seed parameter:
  expect_error(
    object = generate_initial_schools(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes
    ),
    regexp = "parameters list must contain a variable called seed"
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

test_that("generate_initial_workplaces errors if parameter_list does not contain seed", {
  # Establish the list of model parameters:
  parameters_list <- with_default_ach(get_parameters())

  # Generate the population data:
  population_data <- generate_population_data(parameters_list)

  # Remove seed from the parameters list:
  parameters_list$seed <- NULL

  # Check that the generate_initial_schools() function errors due to missing seed parameter:
  expect_error(
    object = generate_initial_workplaces(
      parameters_list = parameters_list,
      initial_age_classes = population_data$age_classes,
      initial_school_settings = population_data$initial_school_settings
    ),
    regexp = "parameters list must contain a variable called seed"
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

test_that("generate_initial_leisure visits distinct settings on distinct days, weighted by size", {
  parameters_list <- get_parameters(list(human_population = 20000, number_initial_S = 20000, number_initial_E = 0, seed = 1))
  leisure_setting_sizes <- c(1, 2, 5, 10, 20, 50, 100, 200)
  leisure <- generate_initial_leisure(parameters_list, leisure_setting_sizes)

  expect_length(leisure, 20000)
  expect_true(all(lengths(leisure) == 7))
  visits <- do.call(rbind, leisure)
  expect_false(any(apply(visits, 1, function(week) anyDuplicated(week[week != 0]) > 0)))
  expect_equal(mean(rowSums(visits != 0)), parameters_list$leisure_mean_number_settings, tolerance = 0.05)
  # Every day of the week is equally likely
  expect_equal(colMeans(visits != 0), rep(mean(visits != 0), 7), tolerance = 0.05)
  # Bigger settings are visited more, but less than in proportion to size, as each person visits a
  # setting at most once
  counts <- tabulate(visits[visits != 0], length(leisure_setting_sizes))
  expect_true(all(diff(counts) > 0))
  expect_lt(counts[8] / counts[1], 200)
})

test_that("generate_initial_leisure errors when there are too few settings to visit", {
  parameters_list <- get_parameters(list(human_population = 1000, number_initial_S = 1000, number_initial_E = 0, seed = 1))
  expect_error(generate_initial_leisure(parameters_list, c(5, 0, 3)), "too few leisure settings")
})

#=======================================#
#===== generate_initial_households =====#
#=======================================#

test_that("generate_initial_households gives exactly human_population individuals", {
  for (human_population in c(1, 7, 500)) {
    parameters_list <- get_parameters(list(
      human_population = human_population, number_initial_S = human_population,
      number_initial_E = 0, seed = 1
    ))
    set.seed(1)
    bundled <- generate_initial_households(parameters_list)
    synthetic <- generate_initial_households(parameters_list, make_synthetic_population())

    for (households in list(bundled, synthetic)) {
      expect_length(households$individual_households, human_population)
      expect_length(households$age_class_vector, human_population)
      expect_setequal(households$individual_households, seq_len(max(households$individual_households)))
    }
  }
})

test_that("generate_initial_households terminates with households of one, or a single household", {
  parameters_list <- get_parameters(list(human_population = 50, number_initial_S = 50, number_initial_E = 0))

  households <- generate_initial_households(parameters_list, data.frame(household_id = 1:3, age = 30))
  expect_setequal(households$individual_households, 1:50)

  households <- generate_initial_households(parameters_list, data.frame(household_id = 1, age = rep(30, 4)))
  expect_equal(max(households$individual_households), 13)
  expect_equal(tabulate(households$individual_households), c(rep(4, 12), 2))
})

test_that("generate_initial_households keeps each sampled household together, with its members' ages", {
  population <- make_synthetic_population()
  parameters_list <- get_parameters(list(human_population = 1000, number_initial_S = 1000, number_initial_E = 0))
  set.seed(1)
  households <- generate_initial_households(parameters_list, population)

  # Each helios household has the age classes of a synthetic household, apart from the last one
  # sampled, which may be cut short
  composition <- function(age_classes, household_ids) {
    tapply(age_classes, household_ids, function(x) paste(sort(x), collapse = " "))
  }
  synthetic <- composition(age_class_from_age(population$age), population$household_id)
  sampled <- composition(households$age_class_vector, households$individual_households)
  expect_in(sampled[-length(sampled)], synthetic)
})
