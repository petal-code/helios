# Convert UV-C parameters to equivalent ACH (eACH)

Converts a UV-C intervention's photophysical parameters into an
equivalent air-change rate (eACH) that can be used as a delta in the
Wells-Riley framework. The conversion is `delta = f * E_avg * k * 3.6`.
The factor 3.6 assumes `E_avg` is in µW/cm^2 and `k` is in cm^2/mJ: it
combines the µW to mW conversion (1e-3) with the per-second to per-hour
conversion (3600). Supplying `E_avg` in mW/cm^2 would overstate eACH by
a factor of 1000.

## Usage

``` r
uv_to_delta(f, E_avg, k)
```

## Arguments

- f:

  Fraction of the room volume that is irradiated (dimensionless, in
  `[0, 1]`).

- E_avg:

  Average fluence rate within the irradiated volume (µW/cm^2).

- k:

  UV inactivation (susceptibility) constant for the target pathogen
  (cm^2/mJ).

## Value

Equivalent ACH contribution from UV-C (units: 1/hour).

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md),
[`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md),
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md),
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md),
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md),
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md)
