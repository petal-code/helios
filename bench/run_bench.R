# Times the pandemic and endemic scenarios over a ladder of population sizes, each case in a fresh
# memory-capped process. Results are appended to the output CSV.
#
# Usage: Rscript bench/run_bench.R [--sizes=10000,30000] [--scenarios=pandemic,endemic]
#   [--reps=3] [--mem-max=20G] [--output=bench/out/results.csv]
#
# By default, sizes up to 30,000 are run 3 times and larger sizes once. The endemic scenario needs
# a cached burn-in for each size: see bench/burnin.R.
source("bench/common.R")

args <- parse_args(list(
  sizes = paste(DEFAULT_SIZES, collapse = ","),
  scenarios = "pandemic,endemic",
  reps = NA,
  mem_max = DEFAULT_MEM_MAX,
  output = "bench/out/results.csv"
))
sizes <- sort(split_numbers(args$sizes))
scenarios <- split_strings(args$scenarios)
check_platform(args$mem_max)

reps_for <- function(human_population) {
  if (!is.na(args$reps)) return(as.integer(args$reps))
  if (human_population <= 30000) 3L else 1L
}

# Rows of this run, for the summary. Each row is also appended to the output as soon as its case
# finishes, so an interrupted run keeps the cases it completed.
rows <- tempfile(fileext = ".csv")
record <- function(row) {
  append_csv(row, rows)
  append_csv(row, args$output)
}

skipped <- character()
for (scenario in scenarios) {
  for (human_population in sizes) {
    if (scenario == "endemic" && !file.exists(burnin_path(human_population))) {
      message("skipping endemic N=", human_population, ": no burn-in, run bench/burnin.R first")
      next
    }
    killed <- FALSE
    for (rep in seq_len(reps_for(human_population))) {
      message(sprintf("%s N=%d rep %d", scenario, human_population, rep))
      case_row <- tempfile(fileext = ".csv")
      status <- run_capped(
        "bench/case.R", c(scenario, human_population, rep, case_row), args$mem_max
      )
      if (status == "ok") {
        record(utils::read.csv(case_row))
      } else {
        record(data.frame(
          date = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          commit = git_commit(),
          scenario = scenario,
          human_population = human_population,
          rep = rep,
          status = if (status == "killed") paste("killed at", args$mem_max) else status,
          simulated_days = NA,
          population_seconds = NA,
          population_peak_mb = NA,
          run_seconds = NA,
          run_peak_mb = NA,
          seconds_per_day = NA
        ))
        # Further reps would most likely fail too
        killed <- status == "killed"
        break
      }
    }
    # Larger populations would be killed too. An error usually doesn't depend on the size, so
    # larger populations are still run after one
    if (killed) {
      larger <- sizes[sizes > human_population]
      if (length(larger) > 0) {
        larger <- paste(sprintf("%d", larger), collapse = ",")
        skipped <- c(skipped, sprintf("%s N=%s", scenario, larger))
      }
      break
    }
  }
}

if (!file.exists(rows)) quit(save = "no")
results <- utils::read.csv(rows)

# Summarise this run: medians over reps, with the endemic timing scaled to the full horizon
ok <- results[results$status == "ok", ]
if (nrow(ok) > 0) {
  summary <- stats::aggregate(
    cbind(population_seconds, run_seconds, seconds_per_day, run_peak_mb) ~ scenario + human_population,
    data = ok, FUN = stats::median, na.action = stats::na.pass
  )
  summary$horizon_hours <- ifelse(
    summary$scenario == "endemic",
    summary$seconds_per_day * ENDEMIC_HORIZON_DAYS,
    summary$run_seconds
  ) / 3600
  print(summary, digits = 3, row.names = FALSE)
}
failures <- results[results$status != "ok", c("scenario", "human_population", "status")]
if (nrow(failures) > 0) print(failures, row.names = FALSE)
for (s in skipped) message("skipped ", s, ": a smaller population was killed at ", args$mem_max)
message("results appended to ", args$output)
# A case killed at the memory cap is a result, but an error is a failure
if (any(results$status == "error")) quit(save = "no", status = 1)
