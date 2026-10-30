# Wells-Riley delta-eACH required to hit a target efficacy

Inverse of
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md).
Given a desired efficacy at a hypothetical location with a specified
baseline ACH and air volume per person, returns the delta-eACH the
intervention needs to add to produce that efficacy. Useful for
calibrating constant-delta interventions to match a target "scalar
efficacy" (e.g. to compare against main-branch runs).

Default values for W-R parameters match those used by the live pipeline
(see Wells-Riley parameters in
[`get_parameters()`](https://mrc-ide.github.io/helios/reference/get_parameters.md)).

Note: because efficacy is nonlinear in baseline ACH, applying this delta
to a population of locations with varying baseline ACH will produce a
*distribution* of realised efficacies centred near (but not exactly
equal to) `target_efficacy`.

## Usage

``` r
efficacy_to_delta(
  target_efficacy,
  baseline_ach,
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

- target_efficacy:

  Desired efficacy in `[0, 1)`.

- baseline_ach:

  Baseline air-change rate of the hypothetical location used for
  calibration (1/hour).

- V:

  Air volume per person in the setting (m^3 per person). Required.

- kD:

  Natural decay rate of the airborne pathogen (1/hour). Default = 0.64.

- r:

  Probability of infection per inhaled FFU. Default = 1.37e-2.

- pi:

  Emission rate of infectious units (FFU/hour). Default = 365.

- I:

  Number of infectious individuals. Default = 1.

- RRtv:

  Respiratory rate \* tidal volume (m^3/hour). Default = 0.45.

- t:

  Exposure window (hours). Default = 4.

## Value

The required delta-eACH (1/hour), suitable for use as the return value
of a constant-delta `delta_function` in
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md).

## See also

Other intervention:
[`calculate_efficacy_from_ach()`](https://mrc-ide.github.io/helios/reference/calculate_efficacy_from_ach.md),
[`delta_to_efficacy()`](https://mrc-ide.github.io/helios/reference/delta_to_efficacy.md),
[`generate_intervention_data()`](https://mrc-ide.github.io/helios/reference/generate_intervention_data.md),
[`generate_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_intervention_switches.md),
[`generate_joint_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_joint_intervention_switches.md),
[`generate_setting_intervention_switches()`](https://mrc-ide.github.io/helios/reference/generate_setting_intervention_switches.md),
[`make_intervention()`](https://mrc-ide.github.io/helios/reference/make_intervention.md),
[`set_intervention_ach()`](https://mrc-ide.github.io/helios/reference/set_intervention_ach.md),
[`uv_to_delta()`](https://mrc-ide.github.io/helios/reference/uv_to_delta.md)
