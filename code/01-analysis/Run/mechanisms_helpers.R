pacman::p_load(tidyverse, arrow, purrr, did)

build_mechanisms_panel <- function(project_root) {
  data_dir <- file.path(project_root, "data", "final_datasets")

  read_periods <- function(prefix) {
    early <- read_parquet(file.path(
      data_dir,
      paste0("panel_comun_1997_2008_", prefix, "_interactions.parquet.gzip")
    )) |>
      filter(year > 1999)

    late <- read_parquet(file.path(
      data_dir,
      paste0("panel_comun_2009_2012_", prefix, "_interactions.parquet.gzip")
    ))

    bind_rows(early, late)
  }

  processing <- read_periods("processing")
  sentencing <- read_periods("sentencing")
  sentencing <- sentencing |>
    rename(
      sentenced_marg_condition = marg_condition,
      sentenced_non_marg_condition = non_marg_condition
    )

  duplicate_crime_columns <- paste0("crime_", 1:14)
  sentencing <- sentencing |>
    select(-any_of(duplicate_crime_columns))

  panel <- processing |>
    left_join(sentencing, by = c("code_inegi", "year", "month"))

  crime_codes <- c(1:6, 8:10, 12:13)

  outcome_families <- list(
    crime_caseloads = paste0("crime_", crime_codes),
    marginal_processing = c(
      "marg_condition",
      "non_marg_condition",
      "formal_prision_marg",
      "formal_prision_non_marg"
    ),
    marginal_sentencing = c(
      "sentenced_marg_condition",
      "sentenced_non_marg_condition",
      "condenado_marg",
      "condenado_non_marg",
      "sent_prison_marg",
      "sent_prison_non_marg",
      "only_sent_money_marg",
      "only_sent_money_non_marg",
      "absolutoria_marg",
      "absolutoria_non_marg"
    ),
    pretrial_by_crime = paste0("formal_prision_crime_", crime_codes),
    release_by_crime = paste0("free_crime_", crime_codes),
    prison_sentence_by_crime = paste0("sent_prison_crime_", crime_codes),
    monetary_sentence_by_crime = paste0(
      "only_sent_money_crime_", crime_codes
    ),
    convictions_by_crime = paste0("condenado_crime_", crime_codes),
    acquittals_by_crime = paste0("absolutoria_crime_", crime_codes),
    sentence_length = paste0("sentence_length_", 1:13)
  )

  requested_outcomes <- unique(unlist(outcome_families, use.names = FALSE))
  missing_outcomes <- setdiff(requested_outcomes, names(panel))
  if (length(missing_outcomes) > 0) {
    stop(
      "Mechanisms columns missing from interaction panels: ",
      paste(missing_outcomes, collapse = ", ")
    )
  }

  monthly_conversion <- tibble(month = 1:12) |>
    mutate(semester = if_else(month <= 6, 1, 2))

  panel <- panel |>
    left_join(monthly_conversion, by = "month") |>
    group_by(code_inegi, year, semester) |>
    summarise(
      across(all_of(requested_outcomes), ~sum(.x, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    rename(actual_time = semester)

  nonzero_outcomes <- requested_outcomes[
    vapply(panel[requested_outcomes], function(x) any(x != 0), logical(1))
  ]
  skipped_outcomes <- setdiff(requested_outcomes, nonzero_outcomes)

  panel <- panel |>
    mutate(across(all_of(nonzero_outcomes), ~log1p(.x)))

  treatment <- read_parquet(
    file.path(data_dir, "treatment_judicial.parquet.gzip")
  ) |>
    left_join(monthly_conversion, by = "month") |>
    group_by(code_inegi, year, semester) |>
    summarise(
      btreat_300KM2 = max(btreat_300KM2, na.rm = TRUE),
      .groups = "drop"
    )

  panel <- panel |>
    left_join(
      treatment,
      by = c("code_inegi", "year", "actual_time" = "semester")
    )

  time_index <- panel |>
    distinct(year, actual_time) |>
    arrange(year, actual_time) |>
    mutate(m_time = row_number())

  panel <- panel |>
    left_join(time_index, by = c("year", "actual_time")) |>
    mutate(treat_post = btreat_300KM2) |>
    group_by(code_inegi) |>
    mutate(
      event_time = {
        treated_periods <- m_time[treat_post > 0]
        if (length(treated_periods) == 0) 0 else treated_periods[[1]]
      },
      treat = as.integer(event_time > 0)
    ) |>
    ungroup()

  controls <- read_parquet(file.path(data_dir, "controls.parquet.gzip")) |>
    select(code_inegi, PMASC18_, VP_TV, VP_RADIO, PNOTRABA) |>
    mutate(across(-code_inegi, ~log1p(.x)))

  panel_controls <- panel |>
    left_join(controls, by = "code_inegi")

  active_families <- map(
    outcome_families,
    ~intersect(.x, nonzero_outcomes)
  )
  active_families <- active_families[lengths(active_families) > 0]

  list(
    panel = panel,
    panel_controls = panel_controls,
    families = active_families,
    skipped_outcomes = skipped_outcomes
  )
}

mechanism_label <- function(variable) {
  crime_labels <- c(
    "1" = "Homicide and Life-Related Offenses",
    "2" = "Bodily Injury and Physical Harm",
    "3" = "Kidnapping and Personal Liberty",
    "4" = "Sexual Liberty and Security",
    "5" = "Property Crimes",
    "6" = "Family and Domestic Violence",
    "8" = "Drug Offenses",
    "9" = "Other Public Health Offenses",
    "10" = "Weapons Offenses",
    "12" = "Public Administration Offenses",
    "13" = "Threats and Other Legal Interests"
  )

  sentence_length_labels <- c(
    "1" = "Less than 1 month",
    "2" = "1 to 12 months",
    "3" = "1 to 3 years",
    "4" = "3 to 5 years",
    "5" = "5 to 7 years",
    "6" = "7 to 9 years",
    "7" = "9 to 11 years",
    "8" = "11 to 13 years",
    "9" = "13 to 15 years",
    "10" = "15 to 17 years",
    "11" = "17 to 19 years",
    "12" = "19 to 21 years",
    "13" = "21 years or more"
  )

  crime_code <- case_when(
    str_detect(variable, "^crime_") ~
      str_remove(variable, "^crime_"),
    str_detect(variable, "^formal_prision_crime_") ~
      str_remove(variable, "^formal_prision_crime_"),
    str_detect(variable, "^free_crime_") ~
      str_remove(variable, "^free_crime_"),
    str_detect(variable, "^sent_prison_crime_") ~
      str_remove(variable, "^sent_prison_crime_"),
    str_detect(variable, "^only_sent_money_crime_") ~
      str_remove(variable, "^only_sent_money_crime_"),
    str_detect(variable, "^condenado_crime_") ~
      str_remove(variable, "^condenado_crime_"),
    str_detect(variable, "^absolutoria_crime_") ~
      str_remove(variable, "^absolutoria_crime_"),
    TRUE ~ NA_character_
  )

  sentence_length_code <- ifelse(
    str_detect(variable, "^sentence_length_"),
    str_remove(variable, "^sentence_length_"),
    NA_character_
  )

  case_when(
    !is.na(crime_code) ~ crime_labels[crime_code],
    str_detect(variable, "^sentence_length_") ~
      sentence_length_labels[sentence_length_code],
    variable == "marg_condition" ~ "Marginal-condition cases",
    variable == "non_marg_condition" ~ "Non-marginal-condition cases",
    variable == "formal_prision_marg" ~
      "Pretrial detention, marginal-condition cases",
    variable == "formal_prision_non_marg" ~
      "Pretrial detention, non-marginal-condition cases",
    variable == "sentenced_marg_condition" ~
      "Sentenced, marginal-condition cases",
    variable == "sentenced_non_marg_condition" ~
      "Sentenced, non-marginal-condition cases",
    variable == "condenado_marg" ~ "Guilty, marginal-condition cases",
    variable == "condenado_non_marg" ~
      "Guilty, non-marginal-condition cases",
    variable == "sent_prison_marg" ~
      "Guilty prison, marginal-condition cases",
    variable == "sent_prison_non_marg" ~
      "Guilty prison, non-marginal-condition cases",
    variable == "only_sent_money_marg" ~
      "Guilty money, marginal-condition cases",
    variable == "only_sent_money_non_marg" ~
      "Guilty money, non-marginal-condition cases",
    variable == "absolutoria_marg" ~
      "Not guilty, marginal-condition cases",
    variable == "absolutoria_non_marg" ~
      "Not guilty, non-marginal-condition cases",
    TRUE ~ variable
  )
}
