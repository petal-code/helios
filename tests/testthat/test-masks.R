#=================================#
#===== Mask wearing (stage 2) =====#
#=================================#

# Parameters for a small population with masks active and a random workplace intervention, which
# draws random numbers before the mask probabilities do
mask_parameters <- function(...) {
  parameters_list <- with_default_ach(get_parameters(overrides = modifyList(
    list(
      human_population = 1000,
      number_initial_S = 990,
      number_initial_E = 10,
      seed = 1,
      mask_active = TRUE,
      mask_timestep = 0,
      mask_inward_far_field_efficacy = 0.5,
      mask_inward_near_field_efficacy = 0.5,
      mask_outward_far_field_efficacy = 0.5,
      mask_outward_near_field_efficacy = 0.5
    ),
    list(...)
  )))
  set_intervention_ach(
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
}

test_that("generate_intervention_data() has no mask probabilities when masks aren't active", {
  parameters_list <- mask_parameters(mask_active = FALSE)
  intervention_data <- generate_intervention_data(
    parameters_list, generate_population_data(parameters_list)
  )
  expect_true("mask_probability" %in% names(intervention_data))
  expect_null(intervention_data$mask_probability)
})

test_that("generate_intervention_data() gives a share of individuals the daily mask probability", {
  parameters_list <- mask_parameters(mask_willing_fraction = 0.3, mask_daily_probability = 0.8)
  population_data <- generate_population_data(parameters_list)
  probability <- generate_intervention_data(parameters_list, population_data)$mask_probability
  expect_length(probability, 1000)
  expect_identical(sum(probability == 0.8), 300L)
  expect_identical(sum(probability == 0), 700L)

  # The same seed picks the same individuals, and another seed others:
  expect_identical(
    generate_intervention_data(parameters_list, population_data)$mask_probability,
    probability
  )
  parameters_list$seed <- 2
  expect_false(identical(
    generate_intervention_data(parameters_list, population_data)$mask_probability,
    probability
  ))
})

test_that("mask probabilities are drawn after, and without changing, the other intervention data", {
  masks_off <- mask_parameters(mask_active = FALSE)
  population_data <- generate_population_data(masks_off)
  # The random number generators' state after generating the intervention data, which the
  # simulation continues from
  generate <- function(parameters_list) {
    intervention_data <- generate_intervention_data(parameters_list, population_data)
    list(intervention_data = intervention_data, rng_state = get_rng_state())
  }
  without_masks <- generate(masks_off)
  others <- c("switches", "far_field_efficacy", "near_field_efficacy", "timestep")

  # With everyone or nobody willing, nothing is drawn:
  for (willing_fraction in c(1, 0)) {
    with_masks <- generate(mask_parameters(
      mask_willing_fraction = willing_fraction, mask_daily_probability = 0.8
    ))
    expect_identical(
      with_masks$intervention_data$mask_probability, rep(0.8 * willing_fraction, 1000)
    )
    expect_identical(with_masks$intervention_data[others], without_masks$intervention_data[others])
    expect_identical(with_masks$rng_state, without_masks$rng_state)
  }

  # Otherwise the draw comes after the intervention's, and continues the stream:
  with_masks <- generate(mask_parameters(mask_willing_fraction = 0.5))
  expect_identical(with_masks$intervention_data[others], without_masks$intervention_data[others])
  expect_false(identical(with_masks$rng_state, without_masks$rng_state))
})

# One population for the tests below. Masks aren't population parameters, so it fits any of them.
mask_population <- generate_population_data(mask_parameters(mask_active = FALSE))

# Runs the S -> E process from timestep 1 to `timesteps`, applying the variables' updates after
# each, and returns the mask probabilities and each timestep's mask state and leisure visits
run_SE_with_masks <- function(parameters_list, timesteps) {
  intervention_data <- generate_intervention_data(parameters_list, mask_population)
  variables_list <- create_variables(parameters_list, mask_population)
  process <- create_SE_process(
    variables_list, list(), parameters_list, mask_population, intervention_data,
    individual::Render$new(timesteps)
  )
  N <- parameters_list$human_population
  mask_worn <- matrix(0L, timesteps, N)
  leisure <- matrix(0L, timesteps, N)
  for (t in seq_len(timesteps)) {
    process(t)
    for (variable in variables_list) {
      variable$.update()
    }
    if (!is.null(variables_list$mask_worn)) {
      mask_worn[t, ] <- variables_list$mask_worn$get_values()
    }
    leisure[t, ] <- variables_list$specific_leisure$get_values()
  }
  list(
    mask_probability = intervention_data$mask_probability,
    mask_worn = mask_worn,
    leisure = leisure
  )
}

test_that("create_variables() adds a mask_worn variable only when masks are active", {
  expect_named(
    create_variables(mask_parameters(mask_active = FALSE), mask_population),
    c("disease_state", "age_class", "specific_leisure")
  )
  variables_list <- create_variables(mask_parameters(), mask_population)
  expect_named(variables_list, c("disease_state", "age_class", "specific_leisure", "mask_worn"))
  expect_equal(variables_list$mask_worn$get_values(), rep(0, 1000))
})

test_that("create_SE_process() refuses mask data that doesn't fit the population", {
  parameters_list <- mask_parameters(mask_willing_fraction = 0.5)
  intervention_data <- generate_intervention_data(parameters_list, mask_population)
  create <- function(intervention_data, variables_list) {
    create_SE_process(
      variables_list, list(), parameters_list, mask_population, intervention_data,
      individual::Render$new(1)
    )
  }
  variables_list <- create_variables(parameters_list, mask_population)
  expect_no_error(create(intervention_data, variables_list))

  broken <- intervention_data
  broken$mask_probability <- broken$mask_probability[-1]
  expect_error(
    create(broken, variables_list),
    "mask_probability must have a probability in \\[0, 1\\] for each of the 1000 individuals"
  )
  broken$mask_probability <- NULL
  expect_error(create(broken, variables_list), "mask_probability must have a probability")

  variables_without_masks <- create_variables(mask_parameters(mask_active = FALSE), mask_population)
  expect_error(
    create(intervention_data, variables_without_masks),
    "variables_list must have a mask_worn variable"
  )
})

test_that("the S -> E process draws who wears a mask when masks start, and then each day", {
  # Masks from timestep 5, half way through day 3 (dt = 0.5). 600 individuals wear a mask with
  # probability 0.5 each day, and 400 never do.
  run <- run_SE_with_masks(
    mask_parameters(mask_timestep = 4, mask_willing_fraction = 0.6, mask_daily_probability = 0.5),
    timesteps = 200
  )
  willing <- run$mask_probability > 0
  expect_true(all(run$mask_worn[1:4, ] == 0))
  expect_true(all(run$mask_worn[, !willing] == 0))

  # It's drawn at timestep 5 and at the start of each day, the even timesteps, and doesn't change in
  # between
  drawn <- c(5, seq(6, 200, by = 2))
  same_as_before <- function(t) identical(run$mask_worn[t, ], run$mask_worn[t - 1, ])
  expect_false(any(vapply(drawn, same_as_before, logical(1))))
  expect_true(all(vapply(seq(7, 199, by = 2), same_as_before, logical(1))))
  expect_equal(mean(run$mask_worn[drawn, willing]), 0.5, tolerance = 0.02)
})

test_that("masks draw no random numbers when everyone always or never wears one", {
  without_masks <- run_SE_with_masks(mask_parameters(mask_active = FALSE), timesteps = 20)

  # Everyone always wears one, from timestep 5:
  always <- run_SE_with_masks(mask_parameters(mask_timestep = 4), timesteps = 20)
  expect_true(all(always$mask_worn[1:4, ] == 0))
  expect_true(all(always$mask_worn[5:20, ] == 1))
  expect_identical(always$leisure, without_masks$leisure)

  # Half always wear one, and half never do:
  half <- run_SE_with_masks(
    mask_parameters(mask_timestep = 4, mask_willing_fraction = 0.5),
    timesteps = 20
  )
  for (t in 5:20) {
    expect_identical(half$mask_worn[t, ], as.integer(half$mask_probability == 1))
  }
  expect_identical(half$leisure, without_masks$leisure)

  # When masks are drawn, the leisure visits are the same until the first draw, at timestep 5:
  drawn <- run_SE_with_masks(
    mask_parameters(mask_timestep = 4, mask_daily_probability = 0.5),
    timesteps = 20
  )
  expect_identical(drawn$leisure[1:5, ], without_masks$leisure[1:5, ])
  expect_false(identical(drawn$leisure[6, ], without_masks$leisure[6, ]))
})

test_that("a run with masks resumed partway through a day matches an uninterrupted run", {
  # Masks are first drawn at timestep 5, half way through day 3, and again at timestep 6. The second
  # part starts half way through day 4, at timestep 7, with the mask state saved at timestep 6.
  parameters_list <- mask_parameters(
    mask_timestep = 4,
    mask_willing_fraction = 0.6,
    mask_daily_probability = 0.5,
    simulation_time = 6
  )
  full <- run_simulation(parameters_list)$result

  parameters_list$simulation_time <- 3
  part_one <- run_simulation(parameters_list)
  part_two <- run_simulation(parameters_list, state = part_one$state)
  expect_equal(rbind(part_one$result, part_two$result), full)
})

test_that("mask_effects() weights the masked infectious individuals and protects the masked", {
  # Individuals 1, 3 and 4 wear a mask, and 2, 3 and 5 are infectious
  mask_worn <- c(1L, 0L, 1L, 1L, 0L)
  inward <- c(far_field = 0.5, near_field = 0.3)
  outward <- c(far_field = 0.4, near_field = 0.9)
  effects <- mask_effects(mask_worn, c(2, 3, 5), inward, outward)
  expect_equal(effects$weight, list(far_field = c(1, 0.6, 1), near_field = c(1, 0.1, 1)))
  expect_equal(
    effects$protection,
    list(far_field = c(0.5, 0, 0.5, 0.5, 0), near_field = c(0.3, 0, 0.3, 0.3, 0))
  )

  # A field where the efficacy is 0 gets no weights or no protection:
  inward[["near_field"]] <- 0
  outward[["far_field"]] <- 0
  effects <- mask_effects(mask_worn, c(2, 3, 5), inward, outward)
  expect_named(effects$weight, "near_field")
  expect_named(effects$protection, "far_field")

  # Nobody infectious:
  expect_identical(
    mask_effects(mask_worn, integer(0), inward, outward)$weight,
    list(near_field = numeric(0))
  )
})

# Runs a simulation of 10 days in which everyone wears a mask from timestep 5, with each mask
# efficacy given in `...`. It starts with 10 infectious individuals, and every setting but schools
# has some near-field transmission.
run_everyone_masked <- function(...) {
  parameters_list <- mask_parameters(
    number_initial_S = 980,
    number_initial_I = 10,
    near_field_fraction_household = 0.5,
    near_field_fraction_workplace = 0.4,
    near_field_fraction_leisure = 0.5,
    near_field_fraction_community = 0.3,
    render_diagnostics = TRUE,
    simulation_time = 10,
    mask_timestep = 4,
    ...
  )
  run_simulation(parameters_list)$result
}

test_that("masks scale the FOI from every setting by what they let through", {
  without_masks <- run_everyone_masked(mask_active = FALSE)
  # In the far field, a mask lets through half inward and half outward, and in the near field a
  # quarter inward and everything outward, so the masks let through a quarter of each FOI in both
  # fields. The workplace intervention combines with them.
  with_masks <- run_everyone_masked(
    mask_inward_far_field_efficacy = 0.5,
    mask_outward_far_field_efficacy = 0.5,
    mask_inward_near_field_efficacy = 0.75,
    mask_outward_near_field_efficacy = 0
  )
  FOI <- paste0("FOI_", c("household", "workplace", "school", "leisure", "community", "total"))
  expect_identical(with_masks[1:4, FOI], without_masks[1:4, FOI])
  # Masks start at timestep 5, when both runs still have the same infectious individuals:
  expect_true(all(without_masks[5, FOI] > 0))
  expect_equal(with_masks[5, FOI], 0.25 * without_masks[5, FOI])
})

test_that("masks that stop all transmission inward or outward stop all new infections", {
  without_masks <- run_everyone_masked(mask_active = FALSE)
  expect_gt(sum(without_masks$E_new[5:20]), 0)
  none_in <- list(mask_inward_far_field_efficacy = 1, mask_inward_near_field_efficacy = 1)
  none_out <- list(mask_outward_far_field_efficacy = 1, mask_outward_near_field_efficacy = 1)
  for (efficacy in list(none_in, none_out)) {
    with_masks <- do.call(run_everyone_masked, efficacy)
    expect_identical(with_masks$E_new[1:4], without_masks$E_new[1:4])
    expect_true(all(with_masks$E_new[5:20] == 0))
  }

  # Masks that remove nothing change nothing:
  with_masks <- run_everyone_masked(
    mask_inward_far_field_efficacy = 0,
    mask_inward_near_field_efficacy = 0,
    mask_outward_far_field_efficacy = 0,
    mask_outward_near_field_efficacy = 0
  )
  expect_identical(with_masks, without_masks)
})
