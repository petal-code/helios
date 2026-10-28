# Sample variables from an log-normal distribution with fixed sum

The final sample is adjusted to ensure that the total sum of samples
equals to `N`. All samples are rounded.

## Usage

``` r
sample_log_normal(N, prop_max = 0.1, meanlog, sdlog)
```

## Arguments

- N:

  An integer giving the sum of generated random variables

- prop_max:

  The proportion of `N` which is the maximum value of a single sample

- meanlog:

  See the `meanlog` argument of
  [`dlnorm()`](https://rdrr.io/r/stats/Lognormal.html)

- sdlog:

  See the `sdlog` argument of
  [`dlnorm()`](https://rdrr.io/r/stats/Lognormal.html)

## See also

Other sampling:
[`sample_negbinom()`](https://mrc-ide.github.io/helios/reference/sample_negbinom.md),
[`sample_offset_truncated_power_distribution()`](https://mrc-ide.github.io/helios/reference/sample_offset_truncated_power_distribution.md)
