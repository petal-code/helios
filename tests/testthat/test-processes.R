
test_that("non-residents add to the size and infectious members of a location", {
  location <- c(1, 1, 2, 0)
  infectious <- 1
  size <- c(2, 1)
  riskiness <- c(1, 1)

  # With no one infectious, non-residents only dilute
  expect_equal(location_FOI(location, infectious, riskiness, 1, size, c(8, 0), 0), c(0.1, 0.1, 0, 0))
  # With everyone infectious, every non-resident is
  expect_equal(location_FOI(location, infectious, riskiness, 1, size, c(8, 3), 1), c(0.9, 0.9, 0.75, 0))
  # Without non-residents, as before
  expect_equal(location_FOI(location, infectious, riskiness, 1, size), c(0.5, 0.5, 0, 0))
})

