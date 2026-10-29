# Profiles one benchmark scenario with Rprof, and saves an interactive profvis report. Time spent in
# C++ code is attributed to the R function that called it.
#
# Usage: Rscript bench/profile.R [--scenario=pandemic] [--size=10000] [--days=30]
#   [--output=bench/out/profile-<scenario>-<size>.html]
#
# The pandemic profile includes population generation. The endemic profile resumes from the cached
# burn-in (see bench/burnin.R).
source("bench/common.R")
load_helios(keep_source = TRUE)

args <- parse_args(list(scenario = "pandemic", size = "10000", days = "30", output = NA))
human_population <- as.numeric(args$size)
days <- as.numeric(args$days)
output <- args$output
if (is.na(output)) {
  output <- sprintf("bench/out/profile-%s-%s.html", args$scenario, args$size)
}
dir.create(dirname(output), showWarnings = FALSE, recursive = TRUE)

parameters <- bench_parameters(args$scenario, human_population, simulation_time = days)
if (args$scenario == "endemic") {
  path <- burnin_path(human_population)
  if (!file.exists(path)) stop("no burn-in for N=", human_population, ": run bench/burnin.R first")
  burnin <- readRDS(path)
}

# The raw profile is kept next to the report, to reopen with profvis::profvis(prof_input = ...)
profile <- paste0(tools::file_path_sans_ext(output), ".Rprof")
Rprof(profile, interval = 0.01, line.profiling = TRUE, filter.callframes = TRUE)
if (args$scenario == "endemic") {
  invisible(run_simulation(parameters, burnin$population, state = burnin$state))
} else {
  invisible(run_simulation(parameters, generate_population_data(parameters)))
}
Rprof(NULL)

print(head(summaryRprof(profile)$by.total, 20))
output <- normalizePath(output, mustWork = FALSE)
# A self-contained report needs pandoc. Without it, the report uses the libraries saveWidget()
# copies to a _files directory alongside it
self_contained <- rmarkdown::pandoc_available()
htmlwidgets::saveWidget(profvis::profvis(prof_input = profile), output, selfcontained = self_contained)
if (self_contained) {
  unlink(sub("\\.html$", "_files", output), recursive = TRUE)
  message("profile saved to ", output)
} else {
  message("profile saved to ", output, " and its _files directory (pandoc not found)")
}
