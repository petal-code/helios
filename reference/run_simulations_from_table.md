# Run helios simulations using table of parameter values

Run helios simulations using table of parameter values

## Usage

``` r
run_simulations_from_table(parameters_table, output_type = "simulations")
```

## Arguments

- parameters_table:

  A data frame in which each row contains parameter values for helios
  model parameters (preferably in data.frame() format)

- output_type:

  A character string instructing the function to output the parameters,
  simulations, or both (default = simulations)

## See also

Other model:
[`run_simulation()`](https://mrc-ide.github.io/helios/reference/run_simulation.md)
