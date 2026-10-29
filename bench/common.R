# Helpers shared by the benchmark scripts. Scripts are run from the repository root, eg.
# `Rscript bench/run_bench.R`, and source this file.

# Days simulated from the approximate equilibrium before the endemic state is cached
BURNIN_DAYS <- 730
# Days timed from the cached endemic state, and the horizon the timing is scaled to
ENDEMIC_TIMED_DAYS <- 365
ENDEMIC_HORIZON_DAYS <- 20 * 365
PANDEMIC_DAYS <- 365

DEFAULT_SIZES <- c(10000, 30000, 100000, 300000)
DEFAULT_MEM_MAX <- "20G"

# Load helios from the working tree, so benchmarks measure the code as it is now
load_helios <- function(keep_source = FALSE) {
  # Source references are needed for line-level profiles
  options(keep.source = keep_source)
  suppressMessages(pkgload::load_all(".", quiet = TRUE))
}

# Parameters for a benchmark scenario: flu, default dt, interventions off
bench_parameters <- function(scenario, human_population, simulation_time, seed = 1) {
  n <- human_population
  overrides <- switch(scenario,
    pandemic = list(
      number_initial_S = n - 5,
      number_initial_E = 5,
      number_initial_I = 0,
      number_initial_R = 0
    ),
    # Approximate flu equilibrium, from inst/getting_endemicity_working.R
    endemic = list(
      number_initial_S = round(0.66 * n),
      number_initial_E = round(0.01 * n),
      number_initial_I = round(0.02 * n),
      number_initial_R = n - round(0.66 * n) - round(0.01 * n) - round(0.02 * n),
      endemic_or_epidemic = "endemic",
      duration_immune = 365,
      prob_inf_external = 0.5 / n
    ),
    stop("unknown scenario: ", scenario)
  )
  overrides <- c(overrides, list(human_population = n, simulation_time = simulation_time, seed = seed))
  parameters <- get_parameters(overrides = overrides, archetype = "flu")
  for (setting in c("household", "workplace", "school", "leisure")) {
    parameters <- set_default_ach(parameters, setting, 4)
  }
  parameters
}

# A short hash of the code and data a burn-in depends on, so that each version of the code has its
# own burn-ins
code_hash <- function() {
  files <- sort(c(list.files(c("R", "data"), full.names = TRUE), "DESCRIPTION", "bench/common.R"))
  sums <- c(
    paste(files, tools::md5sum(files)),
    paste("individual", utils::packageVersion("individual"))
  )
  path <- tempfile()
  writeLines(sums, path)
  substr(unname(tools::md5sum(path)), 1, 8)
}

burnin_path <- function(human_population, seed = 1) {
  file.path(
    tools::R_user_dir("helios", "cache"), "bench",
    sprintf("endemic-%d-seed%d-%s.rds", human_population, seed, code_hash())
  )
}

# Peak resident memory of this process in MB, including memory allocated by C++ code
peak_rss_mb <- function() {
  line <- grep("^VmHWM:", readLines("/proc/self/status"), value = TRUE)
  as.numeric(gsub("[^0-9]", "", line)) / 1024
}

# Reset the peak to the current resident memory, so the next peak_rss_mb() covers only what follows
reset_peak_rss <- function() {
  invisible(gc())
  writeLines("5", "/proc/self/clear_refs")
}

# Run `expr`, returning its value with the elapsed seconds and peak memory it reached
measure <- function(expr) {
  reset_peak_rss()
  start <- proc.time()[["elapsed"]]
  value <- force(expr)
  list(value = value, seconds = proc.time()[["elapsed"]] - start, peak_mb = peak_rss_mb())
}

# The current commit, or NA if git fails, eg. outside a git checkout
git_commit <- function() {
  commit <- system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)
  if (length(commit) != 1) return(NA_character_)
  dirty <- length(system2("git", c("status", "--porcelain", "--untracked-files=no"), stdout = TRUE)) > 0
  if (dirty) paste0(commit, "-dirty") else commit
}

# Parse `--name=value` command line arguments, falling back to `defaults`
parse_args <- function(defaults, args = commandArgs(trailingOnly = TRUE)) {
  for (arg in args) {
    match <- regmatches(arg, regexec("^--([a-z_-]+)=(.*)$", arg))[[1]]
    if (length(match) != 3) stop("arguments must look like --name=value, not ", arg)
    name <- gsub("-", "_", match[2])
    if (!name %in% names(defaults)) stop("unknown argument --", match[2])
    defaults[[name]] <- match[3]
  }
  defaults
}

split_numbers <- function(x) as.numeric(strsplit(x, ",")[[1]])
split_strings <- function(x) strsplit(x, ",")[[1]]

# `command` capped at `mem_max` (eg. "20G", or "none" for no cap)
capped_command <- function(command, mem_max) {
  if (mem_max == "none") return(command)
  c(
    "systemd-run", "--user", "--scope", "--quiet",
    paste0("--property=MemoryMax=", mem_max), "--property=MemorySwapMax=0",
    command
  )
}

# Stop before running any case if peak memory can't be measured here, or memory can't be capped
check_platform <- function(mem_max) {
  if (file.access("/proc/self/clear_refs", 2) != 0) {
    stop("peak memory is measured through /proc/self, so the benchmarks need Linux", call. = FALSE)
  }
  command <- capped_command("true", mem_max)
  if (mem_max != "none" && suppressWarnings(system2(command[1], command[-1])) != 0) {
    stop(
      "can't cap memory with systemd-run --user here: pass --mem-max=none for no cap",
      call. = FALSE
    )
  }
}

# Run an R script in a fresh process, capped at `mem_max` (eg. "20G", or "none" for no cap). A
# process that exceeds the cap is killed rather than swapping. Returns "ok", "killed" (usually for
# running out of memory) or "error".
run_capped <- function(script, args, mem_max) {
  # The Rscript of this R, rather than whichever is first on the PATH
  rscript <- file.path(R.home("bin"), "Rscript")
  command <- capped_command(c(rscript, script, args), mem_max)
  status <- system2(command[1], shQuote(command[-1]))
  # R reports a process killed by SIGKILL as status 9, and a shell reports it as 128 + 9
  if (status %in% c(9, 137)) {
    message("killed: over the ", mem_max, " memory cap?")
    return("killed")
  }
  if (status == 0) "ok" else "error"
}

# Append `rows` to the CSV file at `path`. Stops if the file has other columns, eg. from another
# version of the scripts, rather than adding misaligned rows.
append_csv <- function(rows, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  exists <- file.exists(path) && file.size(path) > 0
  if (exists) {
    columns <- names(utils::read.csv(path, nrows = 1, check.names = FALSE))
    if (!identical(columns, names(rows))) {
      stop(path, " has other columns: move it away or pass another --output", call. = FALSE)
    }
  }
  utils::write.table(rows, path, sep = ",", row.names = FALSE, col.names = !exists, append = exists)
}
