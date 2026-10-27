fixture_zip <- test_path("fixtures", "rti-06075.zip")

lfs_pointer_text <- function(file, sha256 = NULL) {
  if (is.null(sha256)) {
    sha256 <- if (requireNamespace("digest", quietly = TRUE)) {
      digest::digest(file = file, algo = "sha256")
    } else {
      strrep("0", 64)
    }
  }
  c(
    "version https://git-lfs.github.com/spec/v1",
    paste0("oid sha256:", sha256),
    paste0("size ", file.size(file))
  )
}

# Serves the fixture in place of GitHub and counts the zip downloads.
# `zip` overrides what the zip download does, e.g. to simulate an interruption.
local_rti_mock <- function(pointer = lfs_pointer_text(fixture_zip), zip = NULL,
                           env = parent.frame()) {
  calls <- new.env()
  calls$zip <- 0
  calls$urls <- character()
  local_mocked_bindings(
    rti_download_file = function(url, destfile, quiet = FALSE) {
      calls$urls <- c(calls$urls, url)
      if (startsWith(url, "https://raw.githubusercontent.com/")) {
        writeLines(pointer, destfile)
      } else {
        calls$zip <- calls$zip + 1
        if (is.null(zip)) {
          file.copy(fixture_zip, destfile, overwrite = TRUE)
        } else {
          zip(url, destfile)
        }
      }
      invisible(destfile)
    },
    .env = env
  )
  calls
}

local_cache_dir <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_options(helios.cache_dir = dir, .local_envir = env)
  dir
}

cache_contents <- function(dir) {
  list.files(dir, recursive = TRUE, all.files = TRUE, include.dirs = TRUE)
}

# A small extract, as returned by rti_read_extract(): a public school, two private schools
# with a location and a catch-all. Households 1 to 4 have students in the catch-all.
catch_all_extract <- function() {
  people <- data.frame(
    sp_id = 1:9,
    sp_hh_id = c(1, 1, 2, 3, 3, 3, 4, 4, 5),
    age = c(10, 3, 12, 6, 8, 16, 7, 40, 9),
    sp_school_id = c(40, 40, 40, 40, 40, 40, 40, NA, 10),
    sp_work_id = NA
  )
  list(
    people = people,
    schools = data.frame(
      sp_id = c(10, 20, 30, 40),
      prek = c(0, 5, 0, 10),
      kinder = c(10, 5, 5, 10),
      gr01_gr12 = c(90, 40, 45, 980),
      latitude = c(37.75, 37.80, 37.60, 0),
      longitude = c(-122.45, -122.40, -122.50, 0),
      source = c("NCES", "schoolinformation.com", "schoolinformation.com", "schoolinformation.com")
    ),
    catch_all_students = data.frame(
      row = 1:7,
      block_group = c("B", "B", "A", "A", "A", "A", "B"),
      sch = "3",
      schg = c("4", "1", "4", "3", "3", "5", "3"),
      latitude = c(37.61, 37.61, 37.79, 37.79, 37.79, 37.79, 37.61),
      longitude = c(-122.49, -122.49, -122.41, -122.41, -122.41, -122.41, -122.49)
    )
  )
}

test_that("rti_synthetic_schools() doesn't depend on the order of students", {
  x <- catch_all_extract()
  shuffled <- x
  shuffled$catch_all_students <- x$catch_all_students[c(7, 3, 1, 5, 2, 6, 4), ]
  expect_equal(rti_synthetic_schools(shuffled, 3), rti_synthetic_schools(x, 3))
})

test_that("nearest_location() uses great-circle distance", {
  # Across the antimeridian, and at a high latitude where degrees of longitude are short
  expect_equal(nearest_location(0, 179, c(0, 0), c(170, -179)), 2)
  expect_equal(nearest_location(80, 0, c(80, 78), c(10, 0)), 1)
  # Ties go to the first, and repeated points agree
  expect_equal(nearest_location(c(0, 1, 0), c(0, 0, 0), c(0, 0), c(1, -1), chunk_size = 1), c(1, 1, 1))
})

test_that("changing the catch-all method or school size uses the cache", {
  local_cache_dir()
  calls <- local_rti_mock()
  rti_population("06075")
  rti_population("06075", catch_all_schools = "nearest")
  rti_population("06075", synthetic_school_size = 2)
  expect_equal(calls$zip, 1)
})

test_that("a cached population is read without network access", {
  local_cache_dir()
  calls <- local_rti_mock()
  first <- rti_population("06075")

  local_mocked_bindings(rti_download_file = function(...) stop("no network"))
  expect_identical(rti_population("06075"), first)
  expect_equal(calls$zip, 1)
})

test_that("refresh = TRUE downloads again", {
  local_cache_dir()
  calls <- local_rti_mock()
  first <- rti_population("06075")
  second <- rti_population("06075", refresh = TRUE)
  expect_equal(calls$zip, 2)
  expect_identical(second, first)
})

test_that("an interrupted download leaves no cache entry", {
  dir <- local_cache_dir()
  local_rti_mock(zip = function(url, destfile) {
    writeBin(readBin(fixture_zip, "raw", n = 100), destfile)
    stop("connection reset")
  })
  expect_error(rti_population("06075"), "connection reset")
  expect_equal(cache_contents(dir), c("rti", "rti/2010_ver1"))

  # A later call succeeds
  local_rti_mock()
  expect_s3_class(rti_population("06075"), "data.frame")
})

test_that("an interruption does not overwrite an existing cache entry on refresh", {
  dir <- local_cache_dir()
  local_rti_mock()
  first <- rti_population("06075")

  local_rti_mock(zip = function(url, destfile) stop("connection reset"))
  expect_error(rti_population("06075", refresh = TRUE), "connection reset")
  expect_equal(cache_contents(dir), c("rti", "rti/2010_ver1", "rti/2010_ver1/06075.rds"))
  expect_identical(rti_population("06075"), first)
})

test_that("a population can be generated from a downloaded extract in both sampling modes", {
  local_cache_dir()
  local_rti_mock()
  synthetic <- rti_population("06075")

  for (sampling in c("reference", "rti")) {
    parameters <- small_population_parameters(list(school_workplace_sampling = sampling))
    if (sampling == "rti") {
      parameters <- set_synthetic_population_size(parameters, synthetic)
    }
    population_data <- generate_population_data(parameters, synthetic)
    expect_length(population_data$initial_household_settings, parameters$human_population)
    expect_equal(sum(population_data$setting_sizes$household), parameters$human_population)
  }
  # In "rti" mode, there is one school for each school in the extract
  expect_length(population_data$setting_sizes$school, sum(!is.na(unique(synthetic$school_id))))
})

test_that("rti_population() gives the size of each person's school and workplace in the whole US population", {
  local_cache_dir()
  local_rti_mock()
  synthetic <- rti_population("06075")

  # Households in the fixture's order; catch-all students' new schools have no full size
  expect_identical(synthetic$workplace_full_size, as.integer(c(
    12, 3, NA, NA, NA, 250, 250, 40, NA, NA, 5, 3, NA, 5, rep(NA, 9), 12, 40, 40, NA
  )))
  expect_identical(synthetic$school_full_size, as.integer(c(
    NA, NA, 350, 350, NA, 1200, NA, NA, NA, NA, NA, NA, NA, NA, 1200, 1200, NA, NA, 40, 40,
    NA, NA, NA, NA, NA, NA, NA
  )))

  # "nearest" moves the catch-all students to schools with a full size
  nearest <- rti_population("06075", catch_all_schools = "nearest")
  expect_identical(nearest$school_full_size[c(17, 18, 27)], c(1L, 1L, 40L))
})

test_that("an extract cached by an older version is downloaded again", {
  dir <- local_cache_dir()
  calls <- local_rti_mock()
  expected <- rti_population("06075")

  # Before full sizes were kept, the cache had no workplaces or school totals
  path <- file.path(dir, "rti", "2010_ver1", "06075.rds")
  old <- readRDS(path)
  old$workplaces <- NULL
  old$schools$total <- NULL
  saveRDS(old, path)

  expect_message(actual <- rti_population("06075"), "older version")
  expect_identical(actual, expected)
  expect_equal(calls$zip, 2)
  expect_true(rti_extract_is_current(readRDS(path)))
})

test_that("rti_population() downloads a real county", {
  # Check the opt-in first: skip_if_offline() itself uses the network
  skip_if(Sys.getenv("HELIOS_TEST_RTI_DOWNLOAD") != "true", "Set HELIOS_TEST_RTI_DOWNLOAD=true to run")
  skip_on_cran()
  skip_if_offline()
  local_cache_dir()

  # Kent County, Delaware: a 5 MB download
  pop <- rti_population("10001")
  expect_equal(nrow(pop), 157282)
  expect_equal(max(pop$household_id), 60278)
  expect_false(anyNA(pop$household_id))
  expect_false(anyNA(pop$age))
})
