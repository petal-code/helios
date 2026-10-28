# timestep_to_day

Converts a simulation timestep into a simulation-day index. There are
`1 / dt` timesteps per day, so the day is `ceiling(t * dt)`. All
timesteps within the same day map to the same index. The index keeps
counting past day 365 for simulations longer than one year.

## Usage

``` r
timestep_to_day(t, dt)
```

## Arguments

- t:

  The simulation timestep (a positive integer, as passed to a process
  function).

- dt:

  The timestep length as a fraction of a day (e.g. 0.5 for two timesteps
  per day).

## Value

An integer giving the simulation day for timestep `t`.

## See also

Other miscellaneous:
[`generate_betas()`](https://mrc-ide.github.io/helios/reference/generate_betas.md),
[`get_setting_size()`](https://mrc-ide.github.io/helios/reference/get_setting_size.md)
