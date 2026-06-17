###################################################
## Final Paper Results: Figures and Tables
## Output: Paper-ready figures and LaTeX tables for overleaf/v4_draft/results.tex
###################################################

pacman::p_load(tidyverse, arrow, did, patchwork)

rm(list = ls())

find_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  start <- if (length(file_arg) > 0) {
    dirname(normalizePath(sub("^--file=", "", file_arg[[1]])))
  } else if (requireNamespace("rstudioapi", quietly = TRUE) &&
             rstudioapi::isAvailable()) {
    dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path))
  } else {
    getwd()
  }

  current <- normalizePath(start)
  repeat {
    if (dir.exists(file.path(current, ".git"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not find the project root containing .git.")
    }
    current <- parent
  }
}

project_root <- find_project_root()
data_dir <- file.path(project_root, "data", "final_datasets")
figure_dir <- file.path(project_root, "results", "figures", "final_paper")
table_dir <- file.path(project_root, "results", "tables", "final_paper")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path(
  project_root,
  "code", "01-analysis", "Run", "mechanisms_helpers.R"
))

fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "", formatC(x, format = "f", digits = digits))
}

fmt_int <- function(x) {
  ifelse(is.na(x), "", formatC(x, format = "d", big.mark = ","))
}

tex_escape <- function(x) {
  x |>
    str_replace_all("\\\\", "\\\\textbackslash{}") |>
    str_replace_all("([_&#%])", "\\\\\\1")
}

theme_event <- function() {
  theme_classic(base_size = 10) +
    theme(
      axis.text = element_text(color = "black"),
      strip.background = element_blank(),
      strip.text = element_text(face = "bold"),
      panel.grid.major.y = element_line(color = "grey88", linewidth = 0.25),
      panel.spacing = unit(1.2, "lines"),
      legend.position = "bottom"
    )
}

csdid_controls_note <- paste0(
  "The treatment variable is an indicator for federal prison construction ",
  "within 300KM of a municipality. CSDID controls are PMASC18\\_, VP\\_TV, ",
  "VP\\_RADIO, and PNOTRABA."
)

plot_faceted_event <- function(data, labels, filename, ncol = 2) {
  plot_data <- data |>
    filter(
      estimator == "CSDID (Controls)",
      variable %in% names(labels),
      if_all(c(estimate, conf_low, conf_high), is.finite)
    ) |>
    mutate(outcome_label = factor(unname(labels[variable]), levels = labels))

  plot <- ggplot(plot_data, aes(x = time, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "grey50", linetype = "dashed", linewidth = 0.3) +
    geom_errorbar(aes(ymin = conf_low, ymax = conf_high), width = 0, linewidth = 0.28) +
    geom_point(size = 0.9) +
    facet_wrap(vars(outcome_label), scales = "free_y", ncol = ncol) +
    labs(
      x = "Semesters since prison opening",
      y = "Estimated effect, with 95% confidence interval"
    ) +
    theme_event() +
    theme(legend.position = "none")

  rows <- ceiling(length(labels) / ncol)
  ggsave(
    plot,
    filename = file.path(figure_dir, filename),
    device = pdf,
    width = 7.2,
    height = max(3.6, rows * 2.45),
    units = "in"
  )
}

plot_overlay_event <- function(data, labels, filename) {
  dodge <- position_dodge(width = 0.7)
  manual_colors <- c(
    "black",
    "grey72",
    "#2F6FB3",
    "grey45",
    "#7FA6D6",
    "grey25"
  )

  plot_data <- data |>
    filter(
      estimator == "CSDID (Controls)",
      variable %in% names(labels),
      if_all(c(estimate, conf_low, conf_high), is.finite)
    ) |>
    mutate(outcome_label = factor(unname(labels[variable]), levels = labels))

  plot <- ggplot(plot_data, aes(x = time, y = estimate, color = outcome_label)) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "grey50", linetype = "dashed", linewidth = 0.3) +
    geom_errorbar(
      aes(ymin = conf_low, ymax = conf_high),
      width = 0,
      linewidth = 0.25,
      position = dodge
    ) +
    geom_point(aes(shape = outcome_label), size = 1.05, position = dodge) +
    scale_color_manual(
      values = manual_colors[seq_along(labels)],
      name = NULL
    ) +
    scale_shape_manual(
      values = c(16, 17, 15, 18, 3, 4)[seq_along(labels)],
      name = NULL
    ) +
    labs(
      x = "Semesters since prison opening",
      y = "Estimated effect, with 95% confidence interval"
    ) +
    theme_event()

  ggsave(
    plot,
    filename = file.path(figure_dir, filename),
    device = pdf,
    width = 7.2,
    height = 4.4,
    units = "in"
  )
}

plot_overlay_faceted_event <- function(data, plot_map, filename) {
  dodge <- position_dodge(width = 0.7)

  plot_data <- data |>
    filter(
      estimator == "CSDID (Controls)",
      variable %in% plot_map$variable,
      if_all(c(estimate, conf_low, conf_high), is.finite)
    ) |>
    left_join(plot_map, by = "variable") |>
    mutate(
      status_label = factor(status_label, levels = unique(plot_map$status_label)),
      facet_label = factor(facet_label, levels = unique(plot_map$facet_label))
    )

  plot <- ggplot(plot_data, aes(x = time, y = estimate, color = status_label)) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "grey50", linetype = "dashed", linewidth = 0.3) +
    geom_errorbar(
      aes(ymin = conf_low, ymax = conf_high),
      width = 0,
      linewidth = 0.25,
      position = dodge
    ) +
    geom_point(aes(shape = status_label), size = 1.05, position = dodge) +
    facet_wrap(vars(facet_label), scales = "free_y", ncol = 2) +
    scale_color_manual(
      values = c("black", "grey72", "#2F6FB3")[seq_along(unique(plot_map$status_label))],
      name = NULL
    ) +
    scale_shape_manual(
      values = c(16, 17, 15)[seq_along(unique(plot_map$status_label))],
      name = NULL
    ) +
    labs(
      x = "Semesters since prison opening",
      y = "Estimated effect, with 95% confidence interval"
    ) +
    theme_event()

  ggsave(
    plot,
    filename = file.path(figure_dir, filename),
    device = pdf,
    width = 7.2,
    height = 4.2,
    units = "in"
  )
}

make_att_table <- function(att_data, metadata, variables, headers, caption, label,
                           notes, controls_column = TRUE) {
  table_data <- att_data |>
    filter(
      variable %in% variables,
      estimator %in% c("CSDID", "CSDID (Controls)"),
      status == "ok"
    ) |>
    mutate(estimator = factor(estimator, levels = c("CSDID", "CSDID (Controls)")))

  estimate_row <- function(estimator_name) {
    row <- table_data |>
      filter(estimator == estimator_name) |>
      arrange(match(variable, variables))
    c(
      ifelse(
        estimator_name == "CSDID",
        "Effect of federal prison construction, no controls",
        "Effect of federal prison construction, with controls"
      ),
      fmt_num(row$estimate)
    )
  }

  se_row <- function(estimator_name) {
    row <- table_data |>
      filter(estimator == estimator_name) |>
      arrange(match(variable, variables))
    c("", paste0("[", fmt_num(row$std_error), "]"))
  }

  meta <- metadata |>
    filter(variable %in% variables) |>
    arrange(match(variable, variables))

  controls <- if (controls_column) {
    c("Controls", rep("Yes", length(variables)))
  } else {
    c("Controls", rep("", length(variables)))
  }

  rows <- list(
    estimate_row("CSDID"),
    se_row("CSDID"),
    estimate_row("CSDID (Controls)"),
    se_row("CSDID (Controls)"),
    controls,
    c("Observations", fmt_int(meta$observations)),
    c("Pure control mean", fmt_num(meta$control_mean))
  )

  alignment <- paste0("l", str_dup("c", length(variables)))
  header <- paste(c("", headers), collapse = " & ")
  numbers <- paste(c("", paste0("(", seq_along(variables), ")")), collapse = " & ")
  body <- map_chr(rows, ~paste(.x, collapse = " & ")) |>
    paste(collapse = " \\\\\n")

  tex <- paste0(
    "\\begin{table}[!htpb]\\centering\n",
    "\\caption{", caption, "}\n",
    "\\label{", label, "}\n",
    "\\scriptsize\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{@{\\extracolsep{0pt}}", alignment, "}\n",
    "\\hline\\hline\n",
    header, " \\\\\n",
    numbers, " \\\\\n",
    "\\hline\n",
    body, " \\\\\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\item \\emph{Notes:} ", notes, "\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\end{table}\n"
  )

  writeLines(tex, file.path(table_dir, paste0(str_replace_all(label, ":", "_"), ".tex")))
}

make_controls_att_table <- function(att_data, metadata, variables, headers,
                                    caption, label, notes) {
  table_data <- att_data |>
    filter(
      variable %in% variables,
      estimator == "CSDID (Controls)",
      status == "ok"
    ) |>
    arrange(match(variable, variables))

  meta <- metadata |>
    filter(variable %in% variables) |>
    arrange(match(variable, variables))

  alignment <- paste0("l", str_dup("c", length(variables)))
  rows <- list(
    c(
      "Effect of federal prison construction, with controls",
      fmt_num(table_data$estimate)
    ),
    c("", paste0("[", fmt_num(table_data$std_error), "]")),
    c("Controls", rep("Yes", length(variables))),
    c("Observations", fmt_int(meta$observations)),
    c("Pure control mean", fmt_num(meta$control_mean))
  )

  tabular <- paste0(
    "\\begin{tabular}{@{\\extracolsep{0pt}}", alignment, "}\n",
    "\\hline\\hline\n",
    paste(c("", headers), collapse = " & "), " \\\\\n",
    paste(c("", paste0("(", seq_along(variables), ")")), collapse = " & "), " \\\\\n",
    "\\hline\n",
    paste(map_chr(rows, ~paste(.x, collapse = " & ")), collapse = " \\\\\n"), " \\\\\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n"
  )

  if (length(variables) > 8) {
    tabular <- paste0("\\begin{adjustbox}{max width=\\textwidth}\n", tabular, "\\end{adjustbox}\n")
  }

  tex <- paste0(
    "\\begin{table}[!htpb]\\centering\n",
    "\\caption{", caption, "}\n",
    "\\label{", label, "}\n",
    "\\scriptsize\n",
    "\\begin{threeparttable}\n",
    tabular,
    "\\begin{tablenotes}[flushleft]\n",
    "\\item \\emph{Notes:} ", notes, "\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\end{table}\n"
  )

  writeLines(tex, file.path(table_dir, paste0(str_replace_all(label, ":", "_"), ".tex")))
}

build_main_panel <- function() {
  p1 <- read_parquet(file.path(data_dir, "panel_comun_1997_2008.parquet.gzip")) |>
    filter(year > 1999)
  p2 <- read_parquet(file.path(data_dir, "panel_comun_2009_2012.parquet.gzip"))

  monthly_conversion <- tibble(month = 1:12) |>
    mutate(semester = if_else(month <= 6, 1, 2))

  p <- bind_rows(p1, p2) |>
    left_join(monthly_conversion, by = "month") |>
    select(
      code_inegi, year, semester,
      sent_prison, total_processed, formal_prision, free,
      sent_intensive_incl, n_sentenced, only_sent_money,
      absolutoria, condenado
    ) |>
    group_by(code_inegi, year, semester) |>
    summarise(
      across(
        c(
          total_processed, sent_prison, formal_prision, free,
          sent_intensive_incl, n_sentenced, only_sent_money,
          absolutoria, condenado
        ),
        ~sum(.x, na.rm = TRUE)
      ),
      .groups = "drop"
    ) |>
    rename(actual_time = semester) |>
    mutate(
      sentence_length = if_else(n_sentenced != 0, sent_intensive_incl / n_sentenced, 0),
      log_sentence_length = log1p(sentence_length),
      n_sentenced = log1p(n_sentenced),
      sent_prison = log1p(sent_prison),
      total_processed = log1p(total_processed),
      formal_prision = log1p(formal_prision),
      free = log1p(free),
      only_sent_money = log1p(only_sent_money),
      absolutoria = log1p(absolutoria)
    )

  treatment <- read_parquet(file.path(data_dir, "treatment_judicial.parquet.gzip")) |>
    left_join(monthly_conversion, by = "month") |>
    group_by(code_inegi, year, semester) |>
    summarise(btreat_300KM2 = max(btreat_300KM2, na.rm = TRUE), .groups = "drop")

  p <- p |>
    left_join(treatment, by = c("code_inegi", "year", "actual_time" = "semester"))

  time_index <- p |>
    distinct(year, actual_time) |>
    arrange(year, actual_time) |>
    mutate(m_time = row_number())

  p |>
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
}

main_panel <- build_main_panel()
main_controls <- read_parquet(file.path(data_dir, "controls.parquet.gzip")) |>
  select(code_inegi, PMASC18_, VP_TV, VP_RADIO, PNOTRABA) |>
  mutate(across(-code_inegi, ~log1p(.x)))
main_panel_controls <- main_panel |>
  left_join(main_controls, by = "code_inegi")

estimate_main_extra <- function(variable, estimator, xformla, data) {
  model <- att_gt(
    yname = variable,
    tname = "m_time",
    idname = "code_inegi",
    gname = "event_time",
    xformla = xformla,
    control_group = "nevertreated",
    clustervars = "code_inegi",
    data = data
  )
  dynamic <- aggte(MP = model, type = "dynamic", min_e = -60, max_e = 60)
  simple <- aggte(MP = model, type = "simple")

  list(
    event = tibble(
      time = dynamic$egt,
      estimate = dynamic$att.egt,
      std_error = dynamic$se.egt,
      variable = variable,
      estimator = estimator,
      conf_low = estimate - 1.96 * std_error,
      conf_high = estimate + 1.96 * std_error,
      outcome_label = variable
    ),
    att = tibble(
      variable = variable,
      estimator = estimator,
      estimate = simple$overall.att,
      std_error = simple$overall.se,
      status = "ok"
    )
  )
}

extra_vars <- c("sentence_length", "log_sentence_length")
extra_no_controls <- map(
  extra_vars,
  ~estimate_main_extra(.x, "CSDID", ~1, main_panel)
)
extra_controls <- map(
  extra_vars,
  ~estimate_main_extra(
    .x,
    "CSDID (Controls)",
    ~PMASC18_ + VP_TV + VP_RADIO + PNOTRABA,
    main_panel_controls
  )
)

main_events <- readRDS(file.path(
  project_root,
  "results", "rds", "main_event_studies_controls",
  "main_event_studies_with_controls.rds"
)) |>
  bind_rows(map_dfr(c(extra_no_controls, extra_controls), "event"))

processing_att <- readRDS(file.path(
  project_root,
  "results", "rds", "main_att", "processing_att_estimates.rds"
)) |>
  transmute(
    variable,
    estimator = type,
    estimate,
    std_error = se,
    status = "ok"
  )

sentencing_att <- readRDS(file.path(
  project_root,
  "results", "rds", "main_att", "sentencing_att_estimates.rds"
)) |>
  transmute(
    variable,
    estimator = type,
    estimate,
    std_error = se,
    status = "ok"
  ) |>
  bind_rows(map_dfr(c(extra_no_controls, extra_controls), "att"))

main_metadata <- main_panel |>
  summarise(
    across(
      c(
        total_processed, formal_prision, free, n_sentenced, sent_prison,
        only_sent_money, absolutoria, sentence_length, log_sentence_length
      ),
      list(
        observations = ~sum(!is.na(.x)),
        control_mean = ~mean(.x[treat == 0], na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )
  ) |>
  pivot_longer(everything(), names_to = "name", values_to = "value") |>
  extract(name, into = c("variable", "metric"), regex = "(.+)_(observations|control_mean)$") |>
  pivot_wider(names_from = metric, values_from = value)

plot_faceted_event(
  main_events,
  c(
    total_processed = "log(Arrests)",
    formal_prision = "log(Pre-trial Detention)",
    free = "log(Released)"
  ),
  "es_arrests_main.pdf",
  ncol = 2
)

plot_faceted_event(
  main_events,
  c(
    n_sentenced = "log(Total Sentenced)",
    sent_prison = "log(Guilty (Prison))",
    only_sent_money = "log(Guilty (Money))",
    absolutoria = "log(Not Guilty)"
  ),
  "es_sentencing_decisions.pdf",
  ncol = 2
)

plot_faceted_event(
  main_events,
  c(
    sentence_length = "Sentence Length",
    log_sentence_length = "log(1 + Sentence Length)"
  ),
  "es_sentence_length.pdf",
  ncol = 2
)

make_controls_att_table(
  processing_att,
  main_metadata,
  c("total_processed", "formal_prision", "free"),
  c(
    "\\shortstack{log\\\\(Arrests)}",
    "\\shortstack{log\\\\(Pre-trial\\\\ Detention)}",
    "\\shortstack{log\\\\(Released)}"
  ),
  "Average treatment effects on arrests",
  "tab:att_arrests",
  paste0(
    "The table reports CSDID average treatment effects with controls. ",
    "Standard errors clustered by municipality are in brackets. Outcomes ",
    "are transformed using \\(\\log(1+y)\\). The outcome labeled Arrests ",
    "corresponds to total processed individuals in the original data. ",
    csdid_controls_note
  )
)

make_att_table(
  sentencing_att,
  main_metadata,
  c(
    "n_sentenced", "sent_prison", "only_sent_money", "absolutoria",
    "sentence_length", "log_sentence_length"
  ),
  c(
    "\\shortstack{log\\\\(Total\\\\ Sentenced)}",
    "\\shortstack{log\\\\(Guilty\\\\ (Prison))}",
    "\\shortstack{log\\\\(Guilty\\\\ (Money))}",
    "\\shortstack{log\\\\(Not\\\\ Guilty)}",
    "\\shortstack{Sentence\\\\ Length}",
    "\\shortstack{log(1 +\\\\ Sentence\\\\ Length)}"
  ),
  "Average treatment effects on sentencing outcomes",
  "tab:att_sentencing",
  paste0(
    "The table reports CSDID average treatment effects. Standard errors ",
    "clustered by municipality are in brackets. Count outcomes are ",
    "transformed using \\(\\log(1+y)\\). Sentence Length is the average ",
    "sentence length among sentenced individuals, with zeros assigned when ",
    "no individuals are sentenced in a municipality-semester. ",
    csdid_controls_note
  )
)

mechanism_events <- readRDS(file.path(
  project_root,
  "results", "rds", "mechanisms_event_studies_controls",
  "mechanisms_event_studies_with_controls.rds"
))

mechanism_att <- readRDS(file.path(
  project_root,
  "results", "rds", "mechanisms_att",
  "mechanisms_att_estimates.rds"
))

mechanisms <- build_mechanisms_panel(project_root)

estimate_mechanism_extra <- function(variable) {
  model <- att_gt(
    yname = variable,
    tname = "m_time",
    idname = "code_inegi",
    gname = "event_time",
    xformla = ~PMASC18_ + VP_TV + VP_RADIO + PNOTRABA,
    control_group = "nevertreated",
    clustervars = "code_inegi",
    data = mechanisms$panel_controls
  )
  dynamic <- aggte(MP = model, type = "dynamic", min_e = -60, max_e = 60)
  simple <- aggte(MP = model, type = "simple")

  list(
    event = tibble(
      time = dynamic$egt,
      estimate = dynamic$att.egt,
      std_error = dynamic$se.egt,
      variable = variable,
      estimator = "CSDID (Controls)",
      conf_low = estimate - 1.96 * std_error,
      conf_high = estimate + 1.96 * std_error,
      status = "ok",
      error = NA_character_,
      outcome_order = NA_integer_,
      family = "marginal_processing",
      outcome_label = mechanism_label(variable)
    ),
    att = tibble(
      variable = variable,
      estimator = "CSDID (Controls)",
      estimate = simple$overall.att,
      std_error = simple$overall.se,
      conf_low = estimate - 1.96 * std_error,
      conf_high = estimate + 1.96 * std_error,
      conf_low_90 = estimate - 1.645 * std_error,
      conf_high_90 = estimate + 1.645 * std_error,
      status = "ok",
      error = NA_character_,
      outcome_order = NA_integer_,
      family = "marginal_processing",
      outcome_label = mechanism_label(variable)
    )
  )
}

extra_marginal_vars <- c("non_marg_condition", "formal_prision_non_marg")
missing_marginal_vars <- setdiff(extra_marginal_vars, unique(mechanism_att$variable))
if (length(missing_marginal_vars) > 0) {
  extra_marginal_estimates <- map(missing_marginal_vars, estimate_mechanism_extra)
  mechanism_events <- bind_rows(
    mechanism_events,
    map_dfr(extra_marginal_estimates, "event")
  )
  mechanism_att <- bind_rows(
    mechanism_att,
    map_dfr(extra_marginal_estimates, "att")
  )
}

mechanism_metadata <- mechanisms$panel |>
  select(code_inegi, treat, all_of(unique(mechanism_att$variable))) |>
  summarise(
    across(
      -c(code_inegi, treat),
      list(
        observations = ~sum(!is.na(.x)),
        control_mean = ~mean(.x[treat == 0], na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )
  ) |>
  pivot_longer(everything(), names_to = "name", values_to = "value") |>
  extract(name, into = c("variable", "metric"), regex = "(.+)_(observations|control_mean)$") |>
  pivot_wider(names_from = metric, values_from = value)

plot_overlay_event(
  mechanism_events,
  c(
    crime_5 = "Property Crimes",
    crime_2 = "Bodily Injury and Physical Harm",
    crime_1 = "Homicides",
    crime_10 = "Weapons Offenses"
  ),
  "es_crime_type_main.pdf"
)

plot_faceted_event(
  mechanism_events,
  c(
    crime_1 = "Homicides",
    crime_2 = "Bodily Injury and Physical Harm",
    crime_3 = "Kidnapping and Personal Liberty",
    crime_4 = "Sexual Liberty and Security",
    crime_5 = "Property Crimes",
    crime_6 = "Family and Domestic Violence"
  ),
  "app_es_crime_type_all_1.pdf",
  ncol = 2
)

plot_faceted_event(
  mechanism_events,
  c(
    crime_8 = "Drug Offenses",
    crime_9 = "Other Public Health Offenses",
    crime_10 = "Weapons Offenses",
    crime_12 = "Public Administration Offenses",
    crime_13 = "Threats and Other Legal Interests"
  ),
  "app_es_crime_type_all_2.pdf",
  ncol = 2
)

plot_overlay_faceted_event(
  mechanism_events,
  tibble(
    variable = c(
      "marg_condition",
      "non_marg_condition",
      "formal_prision_marg",
      "formal_prision_non_marg"
    ),
    status_label = rep(
      c("Marginal-condition", "Non-marginal-condition"),
      times = 2
    ),
    facet_label = c(
      "Arrests",
      "Arrests",
      "Pre-trial Detention",
      "Pre-trial Detention"
    )
  ),
  "es_marginalized_status.pdf"
)

plot_overlay_event(
  mechanism_events,
  c(
    sentence_length_1 = "Less than 1 month",
    sentence_length_2 = "1 to 12 months",
    sentence_length_13 = "21 years or more"
  ),
  "es_sentence_categories_main.pdf"
)

crime_vars <- c(
  "crime_5", "crime_2", "crime_1", "crime_8", "crime_10",
  "crime_3", "crime_4", "crime_6", "crime_9", "crime_12", "crime_13"
)
crime_headers <- mechanism_att |>
  filter(variable %in% crime_vars) |>
  arrange(match(variable, crime_vars)) |>
  distinct(variable, outcome_label) |>
  pull(outcome_label) |>
  str_replace("Bodily Injury and Physical Harm", "Bodily Injury and Physical Harm") |>
  str_replace("Homicide and Life-Related Offenses", "Homicides") |>
  str_replace("Drug Offenses", "Drugs") |>
  str_replace("Weapons Offenses", "Guns") |>
  str_replace_all(" ", "\\\\\\\\ ")
crime_headers <- paste0("\\shortstack{", crime_headers, "}")

make_controls_att_table(
  mechanism_att,
  mechanism_metadata,
  crime_vars,
  crime_headers,
  "Average treatment effects on arrests by type of crime",
  "tab:att_crime_type",
  paste0(
    "The table reports CSDID average treatment effects with controls. ",
    "Standard errors clustered by municipality are in brackets. Outcomes ",
    "are counts by crime category transformed using \\(\\log(1+y)\\). ",
    csdid_controls_note
  )
)

make_controls_att_table(
  mechanism_att,
  mechanism_metadata,
  c(
    "marg_condition",
    "non_marg_condition",
    "formal_prision_marg",
    "formal_prision_non_marg"
  ),
  c(
    "\\shortstack{Marginal-condition\\\\ arrests}",
    "\\shortstack{Non-marginal-condition\\\\ arrests}",
    "\\shortstack{Marginal-condition\\\\ pre-trial detention}",
    "\\shortstack{Non-marginal-condition\\\\ pre-trial detention}"
  ),
  "Average treatment effects by defendant socioeconomic status",
  "tab:att_marginalized",
  paste0(
    "The table reports CSDID average treatment effects with controls. ",
    "Standard errors clustered by municipality are in brackets. Outcomes ",
    "are transformed using \\(\\log(1+y)\\). Non-marginal-condition outcomes ",
    "are constructed as total cases minus marginal-condition cases before ",
    "the log transformation. ",
    csdid_controls_note
  )
)

sentence_category_vars <- paste0("sentence_length_", 1:13)
sentence_category_headers <- mechanism_att |>
  filter(variable %in% sentence_category_vars) |>
  arrange(match(variable, sentence_category_vars)) |>
  distinct(variable, outcome_label) |>
  pull(outcome_label) |>
  str_replace_all(" ", "\\\\\\\\ ")
sentence_category_headers <- paste0("\\shortstack{", sentence_category_headers, "}")

make_controls_att_table(
  mechanism_att,
  mechanism_metadata,
  sentence_category_vars,
  sentence_category_headers,
  "Average treatment effects by sentence-length category",
  "tab:att_sentence_categories",
  paste0(
    "The table reports CSDID average treatment effects with controls. ",
    "Standard errors clustered by municipality are in brackets. Outcomes ",
    "are counts of sentenced individuals in each sentence-length category, ",
    "transformed using \\(\\log(1+y)\\). ",
    csdid_controls_note
  )
)

message("Final paper figures written to: ", figure_dir)
message("Final paper tables written to: ", table_dir)
