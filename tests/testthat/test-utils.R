test_that("get_setting_size() returns integer vectors for setting as workplace, school, and household", {
  parameters_list <- get_parameters()
  x <- create_variables(parameters_list)
  testthat::expect_vector(
    get_setting_size(x$variables_list, setting = "workplace"),
    ptype = integer()
  )
  testthat::expect_vector(
    get_setting_size(x$variables_list, setting = "school"),
    ptype = integer()
  )
  testthat::expect_vector(
    get_setting_size(x$variables_list, setting = "household"),
    ptype = integer()
  )
})

test_that("get_setting_size() returns integer vectors for setting as workplace, school, and household", {
  parameters_list <- get_parameters()
  x <- create_variables(parameters_list)
  testthat::expect_error(get_setting_size(
    x$variables_list,
    setting = "leisure"
  ))
  testthat::expect_error(get_setting_size(x$variables_list, setting = 1))
})

test_that("seed_rng() seeds both base R's and dqrng's random number generators", {
  draw <- function() list(stats::runif(5), dqrng::dqrunif(5))

  seed_rng(42)
  first <- draw()
  seed_rng(42)
  second <- draw()

  expect_identical(first, second)
})
