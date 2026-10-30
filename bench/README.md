# Benchmarks and profiling

Scripts for measuring how long helios takes and how much memory it needs, and where that time is
spent. They run from the repository root, against the working tree (via `pkgload::load_all()`),
so they measure the code as it currently is. They need the packages listed under
`Config/Needs/bench` in `DESCRIPTION`. `run_bench.R` and `burnin.R` measure memory through Linux's
`/proc`, so they need Linux. `micro.R` and `profile.R` run anywhere.

Results are appended to CSV files in `bench/out/`, tagged with the date and commit, so runs from
different commits can be compared.

## Scenarios

Both scenarios use the flu archetype, the default `dt` and no interventions, over a ladder of
population sizes (10,000, 30,000, 100,000 and 300,000 by default).

* **pandemic**: 365 days, seeded with 5 exposed people.
* **endemic**: 365 days resumed from a cached state, reported as seconds per simulated day and
  scaled to a 20 year horizon. The cached state is made by `burnin.R`, which simulates 730 days
  from an approximate flu equilibrium (`duration_immune = 365`, `prob_inf_external = 0.5 / N`). The
  burn-in isn't included in the timings.

## Running

```sh
# Cache the endemic burn-ins (once per population size; --refresh=true to redo them)
Rscript bench/burnin.R --sizes=10000,30000

# Time both scenarios
Rscript bench/run_bench.R --sizes=10000,30000
```

Burn-ins are cached in `tools::R_user_dir("helios", "cache")`, in its `bench` directory (on Linux,
`~/.cache/R/helios/bench`). Each file name ends with a hash of `R/`, `data/`, `DESCRIPTION`,
`bench/common.R` and the installed version of individual. So a change to any of them needs a new
burn-in, and the burn-ins of other commits stay there, ready to compare. Old ones aren't deleted,
so delete them by hand. A burn-in of 3,000 people takes about 135 KB, and the size grows with the
population.

Each case runs in a fresh R process, so its memory peak isn't affected by earlier cases. Sizes up
to 30,000 are run 3 times and larger ones once, unless `--reps` is given; the summary reports
medians. Timings vary between otherwise identical runs, so close other programs and compare medians.

## Memory

Peak memory is the process's peak resident memory (`VmHWM` in `/proc/self/status`), measured
separately for population generation and the simulation run. It includes memory allocated by
C++ code, such as individual's variables, which R's own memory tools (`gc()`, `bench::mark()`,
`profmem`) don't see.

Each case is capped at 20 GB by default (`--mem-max=24G` to change it, or `--mem-max=none` for no
cap), using `systemd-run`. A case over the cap is killed rather than making the machine swap, and
is recorded as `killed at 20G`. Larger sizes of that scenario are then skipped, as they would be
killed too. A case that fails for another reason is recorded as `error`, and larger sizes are
still run. `run_bench.R` and `burnin.R` then exit with status 1. They stop before running any case
if `systemd-run --user` can't be used, unless `--mem-max=none` is given.

To cap memory for another script, run it with:

```sh
systemd-run --user --scope -p MemoryMax=20G -p MemorySwapMax=0 Rscript bench/micro.R
```

## Microbenchmarks

```sh
Rscript bench/micro.R --sizes=10000,30000 --se-sizes=10000,30000
```

This times:

* population generation, with households sampled from the reference population
  (`population_reference`)
* the S -> E process's setup (`se_setup`) and one timestep, without and with the daily
  reassignment of leisure visits (`se_step`, `se_step_leisure_day`). People are reassigned to
  households of each `--household-sizes` mean size, to show how the cost depends on the number of
  settings at a fixed population size.

## Profiling

```sh
Rscript bench/profile.R --scenario=pandemic --size=10000 --days=30
```

This profiles a scenario with `Rprof`, prints the functions taking the most time, and saves an
interactive flame graph to `bench/out/profile-<scenario>-<size>.html`, to open in a browser. Time
spent in C++ code is attributed to the R function calling it, such as `bitset_count_and_cpp`.

The report is a single file if pandoc is available. Otherwise it needs the `_files` directory saved
next to it. The raw profile is saved next to it too, as a `.Rprof` file, which
`profvis::profvis(prof_input = ...)` or `summaryRprof()` can read again.
