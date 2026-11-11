near_field_settings <- c("household", "workplace", "school", "leisure")
near_field_names <- paste0("near_field_fraction_", near_field_settings)

# The presets in SI Table S5 of the PPE preprint, in the order of near_field_settings:
near_field_table <- list(
  low = c(0.4, 0.15, 0.1, 0.25),
  central = c(0.6, 0.3, 0.2, 0.4),
  high = c(0.8, 0.5, 0.3, 0.55)
)

near_field_fractions <- function(parameters_list) {
  unlist(parameters_list[near_field_names], use.names = FALSE)
}

# Every setting at the default means and SDs of its ACH distribution:
with_default_setting_specific_ach <- function(parameters_list) {
  for (setting in near_field_settings) {
    parameters_list <- set_setting_specific_ach(
      parameters_list,
      setting,
      mean = parameters_list[[paste0("setting_specific_ach_", setting, "_mean")]],
      sd = parameters_list[[paste0("setting_specific_ach_", setting, "_sd")]]
    )
  }
  parameters_list
}

test_that("set_near_field_fractions() sets each preset's values", {
  for (preset in names(near_field_table)) {
    parameters_list <- set_near_field_fractions(get_parameters(), preset)
    expect_identical(near_field_fractions(parameters_list), near_field_table[[preset]])
  }
  # "central" is the default:
  expect_identical(
    near_field_fractions(set_near_field_fractions(get_parameters())),
    near_field_table$central
  )
})

test_that("set_near_field_fractions() sets every fraction to 0 with \"none\" and rejects other presets", {
  parameters_list <- set_near_field_fractions(get_parameters(), "central")
  parameters_list <- set_near_field_fractions(parameters_list, "none")
  expect_identical(near_field_fractions(parameters_list), rep(0, 4))
  expect_identical(parameters_list, get_parameters())

  expect_error(set_near_field_fractions(get_parameters(), "medium"), "should be one of")
})

test_that("set_near_field_fractions() changes no other parameter", {
  parameters_list <- get_parameters(archetype = "sars_cov_2")
  for (preset in c(names(near_field_table), "none")) {
    updated <- set_near_field_fractions(parameters_list, preset)
    expect_identical(names(updated), names(parameters_list))
    other <- setdiff(names(parameters_list), near_field_names)
    expect_identical(updated[other], parameters_list[other])
  }
})

test_that("the near-field fraction presets are in [0, 1] and ordered low <= central <= high", {
  presets <- near_field_fraction_presets()
  expect_identical(presets$setting, near_field_settings)
  for (preset in names(near_field_table)) {
    expect_true(all(presets[[preset]] >= 0 & presets[[preset]] <= 1))
  }
  expect_true(all(presets$low <= presets$central & presets$central <= presets$high))
})

test_that("the near-field fraction presets pass get_parameters() validation", {
  for (preset in names(near_field_table)) {
    fractions <- set_near_field_fractions(get_parameters(), preset)[near_field_names]
    parameters_list <- get_parameters(overrides = fractions)
    expect_identical(near_field_fractions(parameters_list), near_field_table[[preset]])
  }
})

test_that("set_near_field_fractions() doesn't warn at the default ventilation", {
  expect_no_warning(set_near_field_fractions(get_parameters(), "central"))
  expect_no_warning(set_near_field_fractions(with_default_setting_specific_ach(get_parameters()), "central"))
})

test_that("set_near_field_fractions() warns about a setting far from its reference ventilation", {
  parameters_list <- set_default_ach(get_parameters(), "household", 0.5)
  message <- conditionMessage(capture_warning(set_near_field_fractions(parameters_list, "central")))
  expect_match(message, "household (15.8 L/s per person, against 36.7)", fixed = TRUE)
  expect_match(message, "adjust_for_ventilation = TRUE", fixed = TRUE)
  for (setting in c("workplace", "school", "leisure")) {
    expect_no_match(message, setting, fixed = TRUE)
  }
  # The presets are still set as they are:
  updated <- suppressWarnings(set_near_field_fractions(parameters_list, "central"))
  expect_identical(near_field_fractions(updated), near_field_table$central)

  # "none" sets the fractions to 0, so it doesn't depend on the ventilation:
  expect_no_warning(set_near_field_fractions(parameters_list, "none"))
})

test_that("adjust_for_ventilation = TRUE leaves the presets unchanged at the default ventilation", {
  for (preset in names(near_field_table)) {
    parameters_list <- set_near_field_fractions(get_parameters(), preset, adjust_for_ventilation = TRUE)
    expect_equal(near_field_fractions(parameters_list), near_field_table[[preset]], tolerance = 1e-12)
  }
  parameters_list <- set_near_field_fractions(get_parameters(), "none", adjust_for_ventilation = TRUE)
  expect_identical(near_field_fractions(parameters_list), rep(0, 4))
})

test_that("adjust_for_ventilation = TRUE converts the presets through the odds", {
  # A household at 0.5 ACH has a clean air per person of 15.8 L/s, against 36.7 at 2.0 ACH:
  parameters_list <- set_default_ach(get_parameters(), "household", 0.5)
  expect_no_warning(
    updated <- set_near_field_fractions(parameters_list, "central", adjust_for_ventilation = TRUE)
  )
  q <- (0.5 + 0.64) * 50 / 3.6
  q_ref <- (2.0 + 0.64) * 50 / 3.6
  odds <- 0.6 / 0.4 * q / q_ref
  expect_equal(updated$near_field_fraction_household, odds / (1 + odds))
  expect_equal(updated$near_field_fraction_household, 0.393, tolerance = 1e-3)
  # The other settings keep their reference ventilation, so their presets don't change:
  expect_equal(near_field_fractions(updated)[-1], near_field_table$central[-1], tolerance = 1e-12)

  # With the default ACH distributions, the clean air per person is the harmonic mean over
  # locations, about 33.1, 22.8, 8.9 and 7.4 L/s:
  parameters_list <- with_default_setting_specific_ach(get_parameters())
  updated <- set_near_field_fractions(parameters_list, "central", adjust_for_ventilation = TRUE)
  expect_equal(near_field_fractions(updated), c(0.58, 0.26, 0.17, 0.35), tolerance = 0.01)
  # Lower ventilation leaves more of the transmission far-field:
  expect_true(all(near_field_fractions(updated) < near_field_table$central))
})

test_that("convert_near_field_fraction() keeps 0 and 1 and inverts itself", {
  expect_identical(convert_near_field_fraction(0, q_ref = 10, q = 5), 0)
  expect_identical(convert_near_field_fraction(1, q_ref = 10, q = 5), 1)
  converted <- convert_near_field_fraction(0.3, q_ref = 10, q = 25)
  expect_gt(converted, 0.3)
  expect_equal(convert_near_field_fraction(converted, q_ref = 25, q = 10), 0.3)
})

test_that("set_near_field_fractions() requires adjust_for_ventilation to be TRUE or FALSE", {
  for (value in list(NA, "yes", c(TRUE, FALSE), 1)) {
    expect_error(
      set_near_field_fractions(get_parameters(), "central", adjust_for_ventilation = value),
      "adjust_for_ventilation must be TRUE or FALSE"
    )
  }
})

test_that("clean_air_per_person() is (ACH + decay) * volume per person / 3.6 with a uniform ACH", {
  parameters_list <- get_parameters()
  ach <- c(household = 2.0, workplace = 3.1, school = 3.3, leisure = 3.5)
  volume <- c(household = 50, workplace = 27, school = 10, leisure = 8)
  for (setting in near_field_settings) {
    expect_equal(
      clean_air_per_person(parameters_list, setting),
      (ach[[setting]] + 0.64) * volume[[setting]] / 3.6
    )
  }
})

test_that("a joint intervention removes less transmission with the central near-field fractions", {
  parameters_list <- get_parameters(overrides = list(
    simulation_time = 60,
    seed = 1,
    human_population = 2000,
    number_initial_S = 1990,
    number_initial_E = 10
  ), archetype = "sars_cov_2")
  parameters_list <- set_intervention_ach(
    parameters_list,
    setting = "joint",
    coverage_target = "individuals",
    coverage_type = "targeted_riskiness",
    timestep = 1,
    intervention = make_intervention(
      name = "constant_delta",
      delta_function = function(delta) delta,
      delta_params = list(delta = 10),
      coverage = 1
    )
  )
  number_infected <- function(preset) {
    result <- run_simulation(set_near_field_fractions(parameters_list, preset))$result
    parameters_list$human_population - result$S_count[nrow(result)]
  }

  # The intervention can't reduce near-field transmission, so more of the epidemic is left:
  expect_gt(number_infected("central"), number_infected("none"))
})
