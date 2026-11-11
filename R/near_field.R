# Literature-based near-field fractions, from Supplementary Note 3 and Table S5 of the PPE
# preprint (ppe_modelling/notes/near_field_fraction.md). Keep this table, Table S5 and that
# note in step: change all three together. The values were derived at the reference
# ventilation below, which is the default uniform ACH and volume per person in
# get_parameters(), with the default decay rate.
near_field_fraction_presets <- function() {
  data.frame(
    setting = c("household", "workplace", "school", "leisure"),
    low = c(0.4, 0.15, 0.1, 0.25),
    central = c(0.6, 0.3, 0.2, 0.4),
    high = c(0.8, 0.5, 0.3, 0.55),
    reference_ach = c(2.0, 3.1, 3.3, 3.5),
    reference_volume = c(50, 27, 10, 8),
    reference_decay = 0.64,
    stringsAsFactors = FALSE
  )
}

# Baseline clean air per person in `setting` (L/s), the quantity the far-field dose scales
# against. With heterogeneous ACH, far-field riskiness is normalised by the mean infection
# probability, so the matching removal rate is the harmonic mean of ACH + kD over locations.
clean_air_per_person <- function(parameters_list, setting) {
  kD <- parameters_list$wells_riley_decay_rate
  volume <- parameters_list[[paste0("volume_per_person_", setting)]]
  if (isTRUE(parameters_list[[paste0("setting_specific_ach_", setting)]])) {
    mu <- parameters_list[[paste0("setting_specific_ach_", setting, "_mean")]]
    sigma <- parameters_list[[paste0("setting_specific_ach_", setting, "_sd")]]
    mean_inverse <- stats::integrate(
      function(x) truncnorm::dtruncnorm(x, a = 0, mean = mu, sd = sigma) / (x + kD),
      lower = 0, upper = Inf
    )$value
    removal <- 1 / mean_inverse
  } else {
    ach <- parameters_list[[paste0("default_ach_", setting)]]
    if (is.null(ach)) {
      stop("ACH for the ", setting, " setting has not been configured")
    }
    removal <- ach + kD
  }
  # m^3 per hour to L/s
  removal * volume / 3.6
}

# Convert a near-field fraction from clean air q_ref to q. The near-field dose doesn't
# depend on ventilation and the far-field dose scales as 1 / q, so the odds scale with q.
convert_near_field_fraction <- function(fraction, q_ref, q) {
  if (fraction %in% c(0, 1)) return(fraction)
  odds <- fraction / (1 - fraction) * q / q_ref
  odds / (1 + odds)
}

#' Set literature-based near-field fractions
#'
#' @description
#' Sets `near_field_fraction_<setting>` for the household, workplace, school
#' and leisure settings to one of three literature-based presets, or back to
#' 0.
#'
#' The near-field fraction \eqn{\phi_s} of a setting is the share of its
#' baseline transmission that happens at close range to an infectious
#' individual, which ventilation cannot remove. The rest, \eqn{1 - \phi_s}, is
#' far-field (room-scale airborne) transmission, as Wells-Riley describes.
#' Near-field riskiness is 1 in every location and far-field riskiness
#' averages 1, so \eqn{\phi_s} leaves each setting's mean force of infection,
#' and so the calibration of the betas, unchanged. ACH interventions reduce
#' only the far-field part, so they can remove at most \eqn{1 - \phi_s} of a
#' setting's transmission.
#'
#' The presets are the same for every archetype:
#'
#' | Setting   | `"low"` | `"central"` | `"high"` |
#' |-----------|---------|-------------|----------|
#' | household | 0.4     | 0.6         | 0.8      |
#' | workplace | 0.15    | 0.3         | 0.5      |
#' | school    | 0.1     | 0.2         | 0.3      |
#' | leisure   | 0.25    | 0.4         | 0.55     |
#'
#' `"central"` is the best estimate, and `"low"` and `"high"` give the range
#' for sensitivity analyses. `"none"` sets every fraction to 0, the default in
#' [get_parameters()], where all transmission is far-field. The values combine
#' outbreak, household and classroom studies with a model of the exhaled jet
#' (see the references). For a measles-like pathogen, use `"low"`: with very
#' high emission, close contacts are likely to be infected by the room air
#' alone, so the extra close-range dose adds little. That is a judgement
#' rather than a sourced value, so it isn't enforced.
#'
#' The presets were derived at the default uniform ventilation of
#' [get_parameters()]: an ACH of 2.0, 3.1, 3.3 and 3.5, a volume per person of
#' 50, 27, 10 and 8 m^3 (household, workplace, school and leisure) and a decay
#' rate of 0.64/hour. That is a clean air per person,
#' \eqn{(ACH + k_D) V / 3.6}, of 36.7, 28.1, 10.9 and 9.2 L/s. With
#' setting-specific ACH, the clean air per person uses the harmonic mean of
#' \eqn{ACH + k_D} over the ACH distribution, because far-field riskiness is
#' normalised by the mean infection probability. If a setting's clean air per
#' person is more than 25% away from its reference, the function warns.
#'
#' With `adjust_for_ventilation = TRUE`, the function instead converts each
#' preset from its reference clean air per person \eqn{q_{ref}} to the
#' current one, \eqn{q}, through the odds:
#' \deqn{\frac{\phi_s}{1 - \phi_s} = \frac{\phi_{ref}}{1 - \phi_{ref}} \cdot \frac{q}{q_{ref}}}
#' The near-field dose doesn't depend on ventilation and the far-field dose
#' scales as \eqn{1 / q}, so the odds scale with \eqn{q}. For example, a
#' household at 0.5 ACH has a clean air per person of 15.8 L/s, and its
#' central value of 0.6 becomes about 0.39.
#'
#' **Call order:** call this function after [set_default_ach()],
#' [set_setting_specific_ach()] and any `volume_per_person_<setting>` or
#' `wells_riley_decay_rate` overrides, because it reads the ventilation when
#' it is called.
#'
#' @param parameters_list A list of model parameters as generated by
#' [get_parameters()].
#' @param preset Character. One of `"central"` (the default), `"low"`,
#' `"high"` or `"none"`.
#' @param adjust_for_ventilation Logical. If `TRUE`, convert the presets
#' from their reference ventilation to the current one. If `FALSE` (the
#' default), use the presets as they are, and warn about settings far from
#' their reference.
#'
#' @return The input `parameters_list` with `near_field_fraction_household`,
#' `near_field_fraction_workplace`, `near_field_fraction_school` and
#' `near_field_fraction_leisure` set. No other parameter changes.
#'
#' @references
#' Li A, Yen H-L, Leung NHL, Tang JW, Li Y (2026). Influenza A (H1N1) and
#' SARS-CoV-2 transmission in airplanes: quanta profiles and infection control.
#' *Environmental Science & Technology* 60(42): 29955-29965.
#' \doi{10.1021/acs.est.6c09696}
#'
#' Buonanno G, Ricolfi L, Morawska L, Stabile L (2022). Increasing ventilation
#' reduces SARS-CoV-2 airborne transmission in schools: a retrospective cohort
#' study in Italy's Marche region. *Frontiers in Public Health* 10: 1087087.
#' \doi{10.3389/fpubh.2022.1087087}
#'
#' Azimi P, Keshavarz Z, Cedeno Laurent JG, Stephens B, Allen JG (2021).
#' Mechanistic transmission modeling of COVID-19 on the Diamond Princess cruise
#' ship demonstrates the importance of aerosol transmission. *Proceedings of
#' the National Academy of Sciences* 118(8): e2015482118.
#' \doi{10.1073/pnas.2015482118}
#'
#' Cowling BJ, Ip DKM, Fang VJ, et al. (2013). Aerosol transmission is an
#' important mode of influenza A virus spread. *Nature Communications* 4: 1935.
#' \doi{10.1038/ncomms2922}
#'
#' Zhang N, Su B, Chan P-T, Miao T, Wang P, Li Y (2020). Infection spread and
#' high-resolution detection of close contact behaviors. *International
#' Journal of Environmental Research and Public Health* 17(4): 1445.
#' \doi{10.3390/ijerph17041445}
#'
#' Henriques A, Jia W, Aleixo L, et al. (2025). An integrated airborne
#' transmission risk assessment model for respiratory viruses: short- and
#' long-range contributions. *Journal of the Royal Society Interface* 22(223):
#' 20240740. \doi{10.1098/rsif.2024.0740}
#'
#' @examples
#' params <- set_near_field_fractions(get_parameters(archetype = "sars_cov_2"), "central")
#' params$near_field_fraction_household
#'
#' # A less ventilated household, with the presets converted to its ventilation:
#' params <- set_default_ach(get_parameters(archetype = "sars_cov_2"), "household", 0.5)
#' params <- set_near_field_fractions(params, "central", adjust_for_ventilation = TRUE)
#' params$near_field_fraction_household
#'
#' @family parameters
#' @export
set_near_field_fractions <- function(parameters_list,
                                     preset = c("central", "low", "high", "none"),
                                     adjust_for_ventilation = FALSE) {
  preset <- match.arg(preset)
  if (!is.logical(adjust_for_ventilation) || length(adjust_for_ventilation) != 1 ||
      is.na(adjust_for_ventilation)) {
    stop("adjust_for_ventilation must be TRUE or FALSE")
  }
  presets <- near_field_fraction_presets()
  q_ref <- (presets$reference_ach + presets$reference_decay) * presets$reference_volume / 3.6

  far_from_reference <- character(0)
  for (i in seq_len(nrow(presets))) {
    setting <- presets$setting[i]
    if (preset == "none") {
      fraction <- 0
    } else {
      fraction <- presets[[preset]][i]
      q <- clean_air_per_person(parameters_list, setting)
      if (adjust_for_ventilation) {
        fraction <- convert_near_field_fraction(fraction, q_ref[i], q)
      } else if (abs(q / q_ref[i] - 1) > 0.25) {
        far_from_reference <- c(
          far_from_reference,
          sprintf("%s (%.1f L/s per person, against %.1f)", setting, q, q_ref[i])
        )
      }
    }
    parameters_list[[paste0("near_field_fraction_", setting)]] <- fraction
  }

  if (length(far_from_reference) > 0) {
    warning(
      "The near-field fraction presets were derived at the default ventilation of ",
      "get_parameters(). The clean air per person is more than 25% away from it in: ",
      paste(far_from_reference, collapse = ", "), ". ",
      "Use adjust_for_ventilation = TRUE to convert the presets to the current ventilation."
    )
  }

  parameters_list
}
