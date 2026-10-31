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
