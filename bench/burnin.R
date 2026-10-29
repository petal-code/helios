# Caches the population and endemic equilibrium state for each population size, for the endemic
# benchmark to resume from. Each burn-in simulates BURNIN_DAYS from an approximate flu equilibrium,
# in a fresh memory-capped process. Existing burn-ins are kept unless --refresh=true.
#
# Usage: Rscript bench/burnin.R [--sizes=10000,30000] [--mem-max=20G] [--refresh=true]
source("bench/common.R")

args <- parse_args(list(
  sizes = paste(DEFAULT_SIZES, collapse = ","),
  mem_max = DEFAULT_MEM_MAX,
  refresh = "false"
))
sizes <- sort(split_numbers(args$sizes))
check_platform(args$mem_max)

failed <- FALSE
for (human_population in sizes) {
  path <- burnin_path(human_population)
  if (file.exists(path) && !as.logical(args$refresh)) {
    message("keeping burn-in for N=", human_population, ": ", path)
    next
  }
  message("burning in N=", human_population)
  status <- run_capped("bench/case.R", c("burnin", human_population, 0, ""), args$mem_max)
  if (status == "error") failed <- TRUE
  # Larger populations would be killed too. An error usually doesn't depend on the size, so
  # larger populations are still run after one
  if (status == "killed") {
    larger <- sizes[sizes > human_population]
    if (length(larger) > 0) {
      larger <- paste(sprintf("%d", larger), collapse = ",")
      message("skipped N=", larger, ": N=", human_population, " was killed")
    }
    break
  }
}
if (failed) quit(save = "no", status = 1)
