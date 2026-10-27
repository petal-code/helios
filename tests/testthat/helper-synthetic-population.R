# A small synthetic population with the kinds of people found in RTI data: working and non-working
# adults, a 17-year-old with both a school and a workplace, and an elderly worker.
make_synthetic_population <- function(num_households = 200) {
  compositions <- list(c(40, 38, 10, 17), 30, 75, c(45, 6), c(50, 52, 8, 12, 80))
  ages <- lapply(seq_len(num_households), function(h) {
    compositions[[(h - 1) %% length(compositions) + 1]]
  })
  people <- data.frame(
    household_id = rep(seq_len(num_households), lengths(ages)),
    age = unlist(ages)
  )
  person <- seq_len(nrow(people))
  people$school_id <- ifelse(people$age <= 18, person %% 4 + 1, NA)
  works <- (people$age >= 17 & people$age < 70 & people$age != 38) | people$age == 75
  people$workplace_id <- ifelse(works, person %% 10 + 1, NA)
  people
}

# Parameters for a small population, with every setting's ACH set
small_population_parameters <- function(overrides = list()) {
  parameters <- list(human_population = 500, number_initial_S = 490, number_initial_E = 10, seed = 1)
  parameters[names(overrides)] <- overrides
  with_default_ach(get_parameters(parameters))
}

# Parameters for simulating the whole of `synthetic_population` in "rti" mode
rti_population_parameters <- function(synthetic_population, overrides = list()) {
  parameters <- small_population_parameters(c(list(school_workplace_sampling = "rti"), overrides))
  set_synthetic_population_size(parameters, synthetic_population)
}

# Checks that `a` and `b` label the same groups, possibly with different ids
expect_same_grouping <- function(a, b) {
  pairs <- unique(data.frame(a, b))
  expect_false(anyDuplicated(pairs$a) > 0)
  expect_false(anyDuplicated(pairs$b) > 0)
}
