# Wells-Riley efficacy for a single location given baseline ACH and delta

Standalone helper that computes the Wells-Riley efficacy for a single
(baseline_ach, delta) pair, useful for sanity checks and one-off
calibration outside of a full simulation run. Inside `helios`, the
equivalent per-location calculation is performed by
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md)
for all covered locations at once.

Default values for the W-R parameters match those used by the live
pipeline (see Wells-Riley parameters in
[`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)).
`V` is setting-specific (workplace = 27, school = 10, leisure = 8,
household = 50) and must be supplied explicitly.

## Usage

``` r
delta_to_efficacy(
  baseline_ach,
  delta = 0,
  V,
  kD = 0.64,
  r = 0.0137,
  pi = 365,
  I = 1,
  RRtv = 0.45,
  t = 4
)
```

## Arguments

- baseline_ach:

  Baseline air-change rate of the location (1/hour).

- delta:

  Extra eACH added by the intervention (1/hour). Default = 0.

- V:

  Air volume per person in the setting (m^3 per person). Required.

- kD:

  Natural decay rate of the airborne pathogen (1/hour). Default = 0.64.

- r:

  Probability of infection per inhaled FFU. Default = 1.37e-2.

- pi:

  Emission rate of infectious units (FFU/hour). Default = 365.

- I:

  Number of infectious individuals in the location. Default = 1 (and
  cancels in the efficacy ratio).

- RRtv:

  Respiratory rate \* tidal volume (m^3/hour). Default = 0.45.

- t:

  Exposure window for the Wells-Riley calculation (hours). Default = 4.

## Value

Efficacy in `[0, 1]`: the relative reduction in single-exposure
infection probability the intervention produces in this hypothetical
location.

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`efficacy_to_delta()`](https://mrc-ide.github.io/helios/reference/efficacy_to_delta.md),
[`generate_intervention_data()`](https://mrc-ide.github.io/helios/reference/generate_intervention_data.md),
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md),
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md),
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md),
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md),
[`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
