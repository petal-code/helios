check_population_invariant <- function(parameters, synthetic_population = NULL) {
  population_data <- generate_population_data(parameters, synthetic_population)

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

  if (parameters$school_workplace_sampling == "reference") {
    # Each non-elderly individual goes to exactly one of a school or a workplace. This doesn't
    # hold in "rti" mode, where some adults don't work, some children and elderly do, and some
    # children go to both.
    total_activity <- sum(population_data$setting_sizes$workplace) + sum(population_data$setting_sizes$school)
    expect_equal(total_activity, sum(population_data$age_classes != "elderly"))
  } else {
    check_rti_settings(parameters, synthetic_population, population_data)
  }

  invisible(population_data)
}

# Checks that each individual is the synthetic person in the same row, with the same household,
# school and workplace, apart from school staff, who move from their workplace to a school
check_rti_settings <- function(parameters, synthetic_population, population_data) {
  rti <- synthetic_population
  expect_same_grouping(population_data$initial_household_settings, rti$household_id)
  expect_identical(population_data$age_classes, age_class_from_age(rti$age))

  school <- population_data$initial_school_settings
  workplace <- population_data$initial_workplace_settings
  staff <- is.na(rti$school_id) & school != 0

  expect_equal(school[!staff] != 0, !is.na(rti$school_id[!staff]))
  expect_equal(workplace[!staff] != 0, !is.na(rti$workplace_id[!staff]))
  expect_same_grouping(school[!staff], rti$school_id[!staff])
  expect_same_grouping(workplace[!staff], rti$workplace_id[!staff])

  expect_true(all(population_data$age_classes[staff] == "adult"))
  expect_false(anyNA(rti$workplace_id[staff]))
  expect_true(all(workplace[staff] == 0))
  students <- tabulate(school[!staff], length(population_data$setting_sizes$school))
  expect_equal(
    tabulate(school[staff], length(students)),
    ceiling(students / parameters$school_student_staff_ratio)
  )
}

test_that("population data invariants", {
  check_population_invariant(with_default_ach(get_parameters()))
})

test_that("population data invariants with households from a synthetic population", {
  population <- make_synthetic_population()
  population_data <- check_population_invariant(small_population_parameters(), population)
  expect_setequal(population_data$age_classes, AGE_CLASSES)
})

test_that("population data invariants with schools and workplaces from a synthetic population", {
  population <- make_synthetic_population()
  parameters <- rti_population_parameters(population)
  population_data <- check_population_invariant(parameters, population)

  # People with both a school and a workplace, and elderly workers, are kept
  expect_true(any(population_data$initial_school_settings != 0 & population_data$initial_workplace_settings != 0))
  expect_true(any(population_data$age_classes == "elderly" & population_data$initial_workplace_settings != 0))
})

# Parameters and synthetic population for each way of sampling schools and workplaces
sampling_modes <- list(
  reference = list(
    parameters = with_default_ach(get_parameters(list(simulation_time = 10, seed = 1))),
    synthetic_population = NULL
  ),
  rti = list(
    parameters = rti_population_parameters(make_synthetic_population(), list(simulation_time = 10)),
    synthetic_population = make_synthetic_population()
  )
)

for (mode in names(sampling_modes)) {
  parameters <- sampling_modes[[mode]]$parameters
  synthetic_population <- sampling_modes[[mode]]$synthetic_population

  if (mode == "reference") {
    test_that("run_simulation() gives the same result whether or not the population is provided", {
      expected <- run_simulation(parameters)$result
      actual <- run_simulation(parameters, population_data = generate_population_data(parameters))$result

      expect_identical(actual, expected)
    })
  }

  test_that(paste0("a population can be saved to a file and reused (", mode, ")"), {
    population_data <- generate_population_data(parameters, synthetic_population)

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

  test_that(paste0("reusing a population gives the same result on every run (", mode, ")"), {
    population_data <- generate_population_data(parameters, synthetic_population)

    expect_identical(
      run_simulation(parameters, population_data = population_data)$result,
      run_simulation(parameters, population_data = population_data)$result
    )
  })

  test_that(paste0("the same seed gives the same population (", mode, ")"), {
    expect_identical(
      generate_population_data(parameters, synthetic_population),
      generate_population_data(parameters, synthetic_population)
    )
  })
}

# One school and three workplaces with known full sizes. Exactly one adult with a workplace
# and no school becomes school staff, from workplace 1 or 3. Elderly people living alone make up
# 200 people: sample_negbinom() never finishes for leisure in very small populations.
non_resident_population <- function() {
  others <- 190
  data.frame(
    household_id = c(1, 1, 1, 2, 2, 3, 4, 4, 5, 5, 5 + seq_len(others)),
    age = c(8, 10, 40, 12, 41, 42, 43, 70, 30, 31, rep(80, others)),
    school_id = c(1, 1, NA, 1, NA, NA, NA, NA, NA, NA, rep(NA, others)),
    workplace_id = c(NA, NA, 1, NA, 1, 1, 1, 2, 3, 3, rep(NA, others)),
    school_full_size = c(50, 50, NA, 50, NA, NA, NA, NA, NA, NA, rep(NA, others)),
    workplace_full_size = c(NA, NA, 10, NA, 10, 10, 10, NA, 2, 2, rep(NA, others))
  )
}

test_that("schools and workplaces are topped up to their full size with non-residents", {
  people <- non_resident_population()
  without <- rti_population_parameters(people, list(number_initial_S = 499, number_initial_E = 1))
  with <- rti_population_parameters(people, list(non_residents = TRUE, number_initial_S = 499, number_initial_E = 1))
  population_without <- generate_population_data(without, people)
  population_with <- generate_population_data(with, people)

  # 47 students, and 3 staff for 50 students less the 1 for the 3 resident students
  expect_identical(population_with$non_residents$school, 49L)
  # The staff member isn't replaced at their workplace; workplace 2 has no full size
  expect_identical(population_with$non_residents$workplace, c(6L, 0L, 0L))

  # Nothing else changes, including random draws
  expect_identical(population_without$non_residents, list(school = 0L, workplace = c(0L, 0L, 0L)))
  population_with$non_residents <- population_without$non_residents
  expect_identical(population_with, population_without)
})

test_that("non-residents need the full sizes of schools and workplaces", {
  people <- non_resident_population()
  parameters <- rti_population_parameters(people, list(non_residents = TRUE, number_initial_S = 499, number_initial_E = 1))
  people$workplace_full_size <- NULL
  expect_error(generate_population_data(parameters, people), "workplace_full_size")
})

