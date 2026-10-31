test_that("get_parameters() accepts setting-specific betas as vectors matching simulation_time when time_varying_transmission_on is TRUE", {
  expect_no_error(
    get_parameters(
      overrides = list(
        simulation_time = 30,
        time_varying_transmission_on = TRUE,
        beta_household = rep(0.5, 30),
        beta_school = rep(0.5, 30),
        beta_workplace = rep(0.5, 30),
        beta_leisure = rep(0.5, 30),
        beta_community = rep(0.2, 30)
      )
    )
  )
})

test_that("get_parameters() accepts setting-specific betas longer than simulation_time, so they can cover resumed runs", {
  expect_no_error(
    get_parameters(
      overrides = list(
        simulation_time = 30,
        time_varying_transmission_on = TRUE,
        beta_household = rep(0.5, 60),
        beta_school = rep(0.5, 60),
        beta_workplace = rep(0.5, 60),
        beta_leisure = rep(0.5, 60),
        beta_community = rep(0.2, 60)
      )
    )
  )
})

test_that("get_parameters() errors when time_varying_transmission_on is TRUE but a setting-specific beta is still a constant", {
  expect_error(
    get_parameters(
      overrides = list(
        simulation_time = 30,
        time_varying_transmission_on = TRUE
      )
    ),
    regexp = "when time_varying_transmission_on is TRUE, all setting-specific betas must be numeric vectors with at least simulation_time values"
  )
})

test_that("get_parameters() errors when a setting-specific beta is shorter than simulation_time under time-varying transmission", {
  expect_error(
    get_parameters(
      overrides = list(
        simulation_time = 30,
        time_varying_transmission_on = TRUE,
        beta_household = rep(0.5, 30),
        beta_school = rep(0.5, 30),
        beta_workplace = rep(0.5, 30),
        beta_leisure = rep(0.5, 30),
        beta_community = rep(0.2, 10)
      )
    ),
    regexp = "when time_varying_transmission_on is TRUE, all setting-specific betas must be numeric vectors with at least simulation_time values"
  )
})

test_that("get_parameters() errors when a setting-specific beta contains NAs under time-varying transmission", {
  m <- rep(0.5, 30)
  m[10] <- NA
  expect_error(
    get_parameters(
      overrides = list(
        simulation_time = 30,
        time_varying_transmission_on = TRUE,
        beta_household = m,
        beta_school = rep(0.5, 30),
        beta_workplace = rep(0.5, 30),
        beta_leisure = rep(0.5, 30),
        beta_community = rep(0.2, 30)
      )
    ),
    regexp = "when time_varying_transmission_on is TRUE, all setting-specific betas must be numeric vectors with at least simulation_time values"
  )
})

test_that("get_parameters() errors when a setting-specific beta is a vector while time_varying_transmission_on is FALSE", {
  # A vector-valued beta is only meaningful under time-varying transmission; it
  # should error while time-varying transmission is switched off, since a
  # constant is required
  expect_error(
    get_parameters(
      overrides = list(
        time_varying_transmission_on = FALSE,
        beta_community = rep(0.2, 10)
      )
    ),
    regexp = "ERROR: A setting-specific beta has length not equal to 1"
  )
})

test_that("get_parameters() errors when a setting-specific beta has length greater than 1", {
  expect_error(
    object = parameters <- get_parameters(
      overrides = list(
        beta_household = c(0.23),
        beta_school = c(0.45),
        beta_workplace = c(0.01),
        beta_leisure = c(0.455, 0.3),
        beta_community = c(0.4)
      )
    ),
    regexp = "ERROR: A setting-specific beta has length not equal to 1. All setting-specific betas must be of length 1"
  )
})

test_that("get_parameters() errors when the endemic setting is switched on without parameterising duration_immune", {
  expect_error(
    object = get_parameters(
      overrides = list(
        endemic_or_epidemic = 'endemic',
        prob_inf_external = 0.01
      )
    ),
    regexp = "duration_immune must be specified if endemic_or_epidemic is set to endemic"
  )
})

test_that("get_parameters() errors when the endemic setting is switched on without parameterising duration_immune", {
  expect_error(
    object = get_parameters(
      overrides = list(
        endemic_or_epidemic = 'endemic',
        duration_immune = 14
      )
    ),
    regexp = "prob_inf_external must be specified if endemic_or_epidemic is set to endemic"
  )
})

test_that("get_parameters() successfully creates parameter list for endemic setting when all required parameters are parsed", {
  expect_no_error(
    parameters_list <- get_parameters(
      overrides = list(
        endemic_or_epidemic = 'endemic',
        duration_immune = 14,
        prob_inf_external = 0.1
      )
    )
  )
})

test_that("get_parameters() requires each near-field fraction to be a single number in [0, 1]", {
  for (setting in c("household", "workplace", "school", "leisure", "community")) {
    name <- paste0("near_field_fraction_", setting)
    expect_identical(get_parameters()[[name]], 0)
    expect_identical(get_parameters(overrides = setNames(list(0.5), name))[[name]], 0.5)
    for (value in list(-0.1, 1.1, NA_real_, Inf, c(0.2, 0.3), "0.5")) {
      expect_error(
        get_parameters(overrides = setNames(list(value), name)),
        paste0(name, " must be a single number in \\[0, 1\\]")
      )
    }
  }
})

mask_efficacies <- c(
  "mask_inward_far_field_efficacy",
  "mask_inward_near_field_efficacy",
  "mask_outward_far_field_efficacy",
  "mask_outward_near_field_efficacy"
)
masks_on <- list(
  mask_active = TRUE,
  mask_timestep = 0,
  mask_inward_far_field_efficacy = 0.5,
  mask_inward_near_field_efficacy = 0.3,
  mask_outward_far_field_efficacy = 0.6,
  mask_outward_near_field_efficacy = 0.9
)

test_that("get_parameters() has masks off, perfect adherence and no efficacies by default", {
  parameters_list <- get_parameters()
  expect_false(parameters_list$mask_active)
  expect_null(parameters_list$mask_timestep)
  expect_identical(parameters_list$mask_willing_fraction, 1)
  expect_identical(parameters_list$mask_daily_probability, 1)
  for (name in mask_efficacies) {
    expect_null(parameters_list[[name]])
  }
  expect_true(all(c("mask_timestep", mask_efficacies) %in% names(parameters_list)))
})

test_that("get_parameters() requires a mask timestep and the efficacies when masks are active", {
  expect_no_error(get_parameters(overrides = masks_on))
  for (name in c("mask_timestep", mask_efficacies)) {
    expect_error(
      get_parameters(overrides = masks_on[names(masks_on) != name]),
      paste(name, "must be specified if mask_active is TRUE")
    )
  }
})

test_that("get_parameters() checks the values of the mask parameters", {
  for (value in list(NA, 1, "TRUE", c(TRUE, FALSE), NULL)) {
    expect_error(
      get_parameters(overrides = list(mask_active = value)),
      "mask_active must be TRUE or FALSE"
    )
  }

  for (value in list(-1, NA_real_, Inf, c(1, 2), "1")) {
    expect_error(
      get_parameters(overrides = modifyList(masks_on, list(mask_timestep = value))),
      "mask_timestep must be a single number of at least 0"
    )
  }
  expect_identical(
    get_parameters(overrides = modifyList(masks_on, list(mask_timestep = 20)))$mask_timestep,
    20
  )

  for (name in c("mask_willing_fraction", "mask_daily_probability", mask_efficacies)) {
    for (value in list(-0.1, 1.1, NA_real_, Inf, c(0.2, 0.3), "0.5")) {
      expect_error(
        get_parameters(overrides = modifyList(masks_on, setNames(list(value), name))),
        paste0(name, " must be a single number in \\[0, 1\\]")
      )
    }
    expect_identical(
      get_parameters(overrides = modifyList(masks_on, setNames(list(0), name)))[[name]],
      0
    )
  }
  # The fractions have defaults, so they can't be unset:
  expect_error(
    get_parameters(overrides = list(mask_willing_fraction = NULL)),
    "mask_willing_fraction must be a single number in \\[0, 1\\]"
  )

  # Efficacies set while masks are off are still checked:
  expect_error(
    get_parameters(overrides = list(mask_inward_far_field_efficacy = 2)),
    "mask_inward_far_field_efficacy must be a single number in \\[0, 1\\]"
  )
})

test_that("get_parameters() errors when an unrecognised archetype is input", {
  expect_error(get_parameters(archetype = "floo"), "archetype not recognised")
})

test_that("get_parameters() assigns correct parameters for flu archetype", {
  # Generate the parameter list for the fly archetype:
  parameters_list <- get_parameters(archetype = "flu")

  # We are expecting the following flu-specific parameters:
  # duration_exposed = 1
  # duration_infectious = 2
  # beta_household = 0.207
  # beta_school = 0.207
  # beta_workplace = 0.207
  # beta_leisure = 0.207
  # beta_community = 0.069

  # Check that the archetype-specific parameters match the expected values:
  expect_identical(object = parameters_list$duration_exposed, expected = 1)
  expect_identical(object = parameters_list$duration_infectious, expected = 2)
  expect_identical(object = parameters_list$beta_household, expected = 0.207)
  expect_identical(object = parameters_list$beta_school, expected = 0.207)
  expect_identical(object = parameters_list$beta_workplace, expected = 0.207)
  expect_identical(object = parameters_list$beta_leisure, expected = 0.207)
  expect_identical(object = parameters_list$beta_community, expected = 0.069)
})

test_that("get_parameters() assigns correct parameters for SARS-CoV-2 archetype", {
  # Generate the parameter list for the fly archetype:
  parameters_list <- get_parameters(archetype = "sars_cov_2")

  # We are expecting the following flu-specific parameters:
  # duration_exposed = 2
  # duration_infectious = 4
  # beta_household = 0.24
  # beta_school = 0.24
  # beta_workplace = 0.24
  # beta_leisure = 0.24
  # beta_community = 0.08

  # Check that the archetype-specific parameters match the expected values:
  expect_identical(object = parameters_list$duration_exposed, expected = 2)
  expect_identical(object = parameters_list$duration_infectious, expected = 4)
  expect_identical(object = parameters_list$beta_household, expected = 0.24)
  expect_identical(object = parameters_list$beta_school, expected = 0.24)
  expect_identical(object = parameters_list$beta_workplace, expected = 0.24)
  expect_identical(object = parameters_list$beta_leisure, expected = 0.24)
  expect_identical(object = parameters_list$beta_community, expected = 0.08)
})

test_that("get_parameters() assigns correct parameters for measles archetype", {
  # Generate the parameter list for the fly archetype:
  parameters_list <- get_parameters(archetype = "measles")

  # We are expecting the following flu-specific parameters:
  # duration_exposed = 8
  # duration_infectious = 5
  # beta_household = 1.26
  # beta_school = 1.26
  # beta_workplace = 1.26
  # beta_leisure = 1.26
  # beta_community = 0.044

  # Check that the archetype-specific parameters match the expected values:
  expect_identical(object = parameters_list$duration_exposed, expected = 8)
  expect_identical(object = parameters_list$duration_infectious, expected = 5)
  expect_identical(object = parameters_list$beta_household, expected = 1.26)
  expect_identical(object = parameters_list$beta_school, expected = 1.26)
  expect_identical(object = parameters_list$beta_workplace, expected = 1.26)
  expect_identical(object = parameters_list$beta_leisure, expected = 1.26)
  expect_identical(object = parameters_list$beta_community, expected = 0.42)
})

test_that("run_simulation() works when a parameter archetype specified", {
  # Generate the parameter list for the fly archetype:
  parameters_list <- with_default_ach(get_parameters(
    overrides = list(simulation_time = 3),
    archetype = "flu"
  ))

  # Run the simulation:
  simulation_example <- run_simulation(parameters_list = parameters_list)$result

  # Check that the output contains some expected column names and that it is a data.frame:
  expect_true(all(
    c("S_count", "E_count", "I_mild_count", "I_hosp_count", "R_count") %in%
      names(simulation_example)
  ))
  expect_true(object = is.data.frame(simulation_example))
})
