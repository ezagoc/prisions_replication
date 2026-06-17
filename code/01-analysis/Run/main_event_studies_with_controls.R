###################################################
## Main Results: Event Studies With and Without Controls
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Output: Main event-study estimates comparing CSDID specifications
###################################################

pacman::p_load(tidyverse, arrow, purrr, did, patchwork)

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
rds_dir <- file.path(project_root, "results", "rds", "main_event_studies_controls")
figure_dir <- file.path(
  project_root, "results", "figures", "main_event_studies_controls"
)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

p1 <- read_parquet(file.path(data_dir, "panel_comun_1997_2008.parquet.gzip")) |>
  filter(year > 1999)
p2 <- read_parquet(file.path(data_dir, "panel_comun_2009_2012.parquet.gzip"))
p <- bind_rows(p1, p2)

treatment <- read_parquet(file.path(data_dir, "treatment_judicial.parquet.gzip"))
controls <- read_parquet(file.path(data_dir, "controls.parquet.gzip")) |>
  select(code_inegi, POBTOT:PHOGJEFF) |>
  mutate(across(c(POBTOT:PHOGJEFF), ~log1p(.x)))

monthly_conversion <- tibble(month = 1:12) |>
  mutate(semester = if_else(month <= 6, 1, 2))

p <- p |>
  left_join(monthly_conversion, by = "month") |>
  select(
    code_inegi, CVE_ENT, year, semester,
    sent_prison, total_processed, formal_prision, free,
    sent_intensive, sent_intensive_incl, n_sentenced,
    only_sent_money, absolutoria, condenado
  ) |>
  group_by(code_inegi, year, semester) |>
  summarise(
    across(
      c(
        total_processed, sent_prison, formal_prision, free,
        sent_intensive, sent_intensive_incl, n_sentenced,
        only_sent_money, absolutoria, condenado
      ),
      ~sum(.x, na.rm = TRUE)
    ),
    .groups = "drop"
  ) |>
  rename(actual_time = semester)

p <- p |>
  mutate(
    rate_free = ifelse(total_processed != 0, free / total_processed, 0),
    processed_0 = as.integer(total_processed == 0),
    rate_formal = ifelse(
      total_processed != 0,
      formal_prision / total_processed,
      0
    ),
    sent_intensive = log1p(ifelse(
      n_sentenced != 0,
      sent_intensive_incl / n_sentenced,
      0
    )),
    rate_sent_cond = ifelse(condenado != 0, sent_prison / condenado, 0),
    rate_cond = ifelse(n_sentenced != 0, condenado / n_sentenced, 0),
    rate_only_money = ifelse(condenado != 0, only_sent_money / condenado, 0),
    condenado_0 = as.integer(condenado == 0),
    sentenced_0 = as.integer(n_sentenced == 0),
    n_sentenced = log1p(n_sentenced),
    sent_prison = log1p(sent_prison),
    total_processed = log1p(total_processed),
    formal_prision = log1p(formal_prision),
    free = log1p(free),
    only_sent_money = log1p(only_sent_money),
    absolutoria = log1p(absolutoria)
  )

treatment <- treatment |>
  left_join(monthly_conversion, by = "month") |>
  group_by(code_inegi, year, semester) |>
  summarise(btreat_300KM2 = max(btreat_300KM2, na.rm = TRUE), .groups = "drop")

p <- p |>
  left_join(
    treatment,
    by = c("code_inegi", "year", "actual_time" = "semester")
  )

time_index <- p |>
  distinct(year, actual_time) |>
  arrange(year, actual_time) |>
  mutate(m_time = row_number())

p <- p |>
  left_join(time_index, by = c("year", "actual_time")) |>
  mutate(treat_post = btreat_300KM2) |>
  group_by(code_inegi) |>
  mutate(
    event_time = {
      treated_periods <- m_time[treat_post > 0]
      if (length(treated_periods) == 0) 0 else treated_periods[[1]]
    },
    treat = as.integer(event_time > 0),
    time_to_event = ifelse(treat == 1, m_time - event_time, 0)
  ) |>
  ungroup()

p_controls <- p |>
  left_join(controls, by = "code_inegi")

estimate_event_study <- function(variable, estimator, xformla, data) {
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

  tibble(
    time = dynamic$egt,
    estimate = dynamic$att.egt,
    std_error = dynamic$se.egt,
    variable = variable,
    estimator = estimator,
    conf_low = estimate - 1.96 * std_error,
    conf_high = estimate + 1.96 * std_error
  )
}

estimate_level_pair <- function(variable) {
  bind_rows(
    estimate_event_study(variable, "CSDID", ~1, p),
    estimate_event_study(
      variable,
      "CSDID (Controls)",
      ~PMASC18_ + VP_TV + VP_RADIO + PNOTRABA,
      p_controls
    )
  )
}

estimate_rate_pair <- function(variable, zero_control) {
  bind_rows(
    estimate_event_study(
      variable,
      "CSDID",
      as.formula(paste0("~", zero_control)),
      p
    ),
    estimate_event_study(
      variable,
      "CSDID (Controls)",
      as.formula(
        paste0("~ PMASC18_ + VP_TV + VP_RADIO + PNOTRABA + ", zero_control)
      ),
      p_controls
    )
  )
}

outcome_groups <- list(
  sentence_levels = c(
    only_sent_money = "log Guilty (Money)",
    absolutoria = "log Not Guilty",
    sent_prison = "log Guilty (Prison)",
    sent_intensive = "Time Sentenced",
    n_sentenced = "log Total Sentenced"
  ),
  sentence_rates = c(
    rate_cond = "Guilty / Sentenced",
    rate_sent_cond = "Prison / Guilty",
    rate_only_money = "Money / Guilty"
  ),
  processing_levels = c(
    total_processed = "log Total Processed",
    formal_prision = "log Pretrial Detention",
    free = "log Released"
  ),
  processing_rates = c(
    rate_formal = "Pretrial Detention / Processed",
    rate_free = "Released / Processed"
  )
)

rate_controls <- c(
  rate_cond = "sentenced_0",
  rate_sent_cond = "condenado_0",
  rate_only_money = "condenado_0",
  rate_formal = "processed_0",
  rate_free = "processed_0"
)

level_variables <- c(outcome_groups$sentence_levels, outcome_groups$processing_levels)
rate_variables <- c(outcome_groups$sentence_rates, outcome_groups$processing_rates)

level_estimates <- map_dfr(names(level_variables), estimate_level_pair)
rate_estimates <- map_dfr(
  names(rate_variables),
  ~estimate_rate_pair(.x, rate_controls[[.x]])
)

all_estimates <- bind_rows(level_estimates, rate_estimates) |>
  mutate(
    outcome_label = case_when(
      variable %in% names(level_variables) ~ unname(level_variables[variable]),
      variable %in% names(rate_variables) ~ unname(rate_variables[variable]),
      TRUE ~ variable
    )
  )

saveRDS(
  all_estimates,
  file.path(rds_dir, "main_event_studies_with_controls.rds")
)

plot_event_group <- function(labels, group_name) {
  plot_data <- all_estimates |>
    filter(variable %in% names(labels)) |>
    mutate(
      outcome_label = factor(outcome_label, levels = unname(labels)),
      estimator = factor(estimator, levels = c("CSDID", "CSDID (Controls)"))
    )

  plot <- ggplot(plot_data, aes(x = time, y = estimate, color = estimator)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(
      aes(ymin = conf_low, ymax = conf_high, fill = estimator),
      alpha = 0.18,
      color = NA
    ) +
    geom_line(linewidth = 0.35) +
    facet_wrap(vars(outcome_label), scales = "free_y", ncol = 2) +
    labs(
      x = "Time relative to treatment (semesters)",
      y = "Estimated effect",
      color = "Estimator",
      fill = "Estimator",
      caption = "Shaded areas are 95% confidence intervals."
    ) +
    theme_bw() +
    theme(
      legend.position = "bottom",
      plot.caption = element_text(hjust = 0.5)
    ) +
    scale_x_continuous(expand = expansion(mult = c(0.03, 0.03)))

  rows <- ceiling(length(labels) / 2)
  ggsave(
    plot,
    filename = file.path(figure_dir, paste0(group_name, "_event_studies.pdf")),
    device = pdf,
    width = 11,
    height = max(4.5, rows * 3),
    units = "in"
  )
}

iwalk(outcome_groups, plot_event_group)
