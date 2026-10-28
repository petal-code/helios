# Sample variables from a negative binomial distribution with fixed sum

This function samples from a negative binomial distribution. Rather than
specifying the total number of samples, as with `rnbinom`, this function
takes as input an integer `N` which the resulting samples must sum to.
This is achieved by adjusting the final sample. As such, the resulting
samples are not strictly speaking from a negative binomial distribution.

## Usage

``` r
sample_negbinom(N, prop_max = 0.1, mu, size)
```

## Arguments

- N:

  An integer giving the sum of generated random variables

- prop_max:

  The proportion of `N` which is the maximum value of a single sample

- mu:

  See the `mu` argument of
  [`rnbinom()`](https://rdrr.io/r/stats/NegBinomial.html)

- size:

  See the `size` argument of
  [`rnbinom()`](https://rdrr.io/r/stats/NegBinomial.html)

## See also

Other sampling:
[`sample_log_normal()`](https://mrc-ide.github.io/helios/reference/sample_log_normal.md),
[`sample_offset_truncated_power_distribution()`](https://mrc-ide.github.io/helios/reference/sample_offset_truncated_power_distribution.md)
