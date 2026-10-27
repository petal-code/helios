# Microbenchmarks of population generation and the S -> E process. Timings only: bench::mark()'s
# memory measurement misses memory allocated by C++ code, so use run_bench.R for peak memory.
#
# Usage: Rscript bench/micro.R [--sizes=10000,30000,100000,300000] [--rti=10001]
#   [--se-sizes=10000,30000,100000] [--household-sizes=2.5,10,50] [--iterations=3]
#   [--output=bench/out/micro.csv]
#
# --rti takes a comma-separated list of FIPS codes (see rti_population()), or "none" to skip.
source("bench/common.R")
load_helios()

args <- parse_args(list(
  sizes = paste(DEFAULT_SIZES, collapse = ","),
  rti = "10001",
  se_sizes = "10000,30000,100000",
  household_sizes = "2.5,10,50",
  iterations = "3",
  output = "bench/out/micro.csv"
))
iterations <- as.integer(args$iterations)
commit <- git_commit()

time_it <- function(fn) {
  result <- bench::mark(fn(), iterations = iterations, check = FALSE, memory = FALSE, filter_gc = FALSE)
  c(min_seconds = as.numeric(result$min), median_seconds = as.numeric(result$median))
}

results <- list()
record <- function(benchmark, population, timing, fips = NA) {
  row <- data.frame(
    date = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    commit = commit,
    benchmark = benchmark,
    fips = fips,
    human_population = length(population$initial_household_settings),
    n_households = length(population$setting_sizes$household),
    n_settings = sum(lengths(population$setting_sizes)),
    min_seconds = timing[["min_seconds"]],
    median_seconds = timing[["median_seconds"]],
    iterations = iterations
  )
  message(sprintf(
    "%-20s N=%-8d settings=%-8d median %.3f s", benchmark, row$human_population, row$n_settings,
    row$median_seconds
  ))
  results[[length(results) + 1]] <<- row
}

# Population generation, with households sampled from the reference synthetic population
for (human_population in split_numbers(args$sizes)) {
  parameters <- bench_parameters("pandemic", human_population, simulation_time = 1)
  population <- generate_population_data(parameters)
  record("population_reference", population, time_it(function() generate_population_data(parameters)))
}

# Population generation from an RTI synthetic population. Reading it is timed separately.
if (args$rti != "none") {
  for (fips in split_strings(args$rti)) {
    synthetic_population <- rti_population(fips)
    parameters <- bench_parameters("pandemic", nrow(synthetic_population), simulation_time = 1)
    parameters$school_workplace_sampling <- "rti"
    population <- generate_population_data(parameters, synthetic_population)
    record("rti_population", population, time_it(function() rti_population(fips)), fips)
    record(
      "population_rti", population,
      time_it(function() generate_population_data(parameters, synthetic_population)), fips
    )
  }
}

# Reassign people to households with the given mean size, keeping everyone's other settings, to show
# how the S -> E process's cost depends on the number of settings at a fixed population size.
with_household_size <- function(population, mean_size) {
  n <- length(population$initial_household_settings)
  n_households <- max(1, round(n / mean_size))
  households <- sample(rep_len(seq_len(n_households), n))
  population$initial_household_settings <- households
  population$setting_sizes$household <- tabulate(households, n_households)
  population$household_specific_ach <- rep_len(population$household_specific_ach, n_households)
  population$household_specific_riskiness <- rep_len(population$household_specific_riskiness, n_households)
  population
}

# The S -> E process: its setup, and one timestep with and without the daily reassignment of
# leisure visits. Updates queued by the process aren't applied, so every call sees the same state.
for (human_population in split_numbers(args$se_sizes)) {
  parameters <- bench_parameters("pandemic", human_population, simulation_time = 1)
  base_population <- generate_population_data(parameters)
  for (mean_size in split_numbers(args$household_sizes)) {
    population <- with_household_size(base_population, mean_size)
    variables <- create_variables(parameters, population)
    events <- create_events(variables_list = variables, parameters_list = parameters)
    intervention_data <- generate_intervention_data(parameters, population)
    renderer <- individual::Render$new(2)
    create <- function() {
      create_SE_process(variables, events, parameters, population, intervention_data, renderer)
    }
    record("se_setup", population, time_it(create))
    process <- create()
    # With dt = 0.5, leisure visits are reassigned on whole days only
    record("se_step", population, time_it(function() process(1)))
    record("se_step_leisure_day", population, time_it(function() process(2)))
  }
}

append_csv(do.call(rbind, results), args$output)
message("results appended to ", args$output)
