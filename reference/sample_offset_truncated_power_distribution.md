# Sample variables from an offset truncated power distribution with fixed sum

Default values adapted from Ferguson et al. (2005). The final sample is
adjusted to ensure that the total sum of samples equals to `N`.

## Usage

``` r
sample_offset_truncated_power_distribution(
  N,
  prop_max = 0.1,
  a = 5.36,
  c = 1.34
)
```

## Arguments

- N:

  An integer giving the sum of generated random variables

- prop_max:

  The proportion of `N` which is the maximum value of a single sample

- a:

  A parameter of the distribution (?)

- c:

  A parameter of the distribution (?)

## See also

Other sampling:
[`sample_negbinom()`](https://mrc-ide.github.io/helios/reference/sample_negbinom.md)
