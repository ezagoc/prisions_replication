###################################################
## Mechanisms: Event Studies With and Without Controls
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Output: Mechanism event-study estimates comparing CSDID specifications
###################################################

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
source(file.path(
  project_root,
  "code", "01-analysis", "Run", "mechanisms_helpers.R"
))

rds_dir <- file.path(
  project_root, "results", "rds", "mechanisms_event_studies_controls"
)
figure_dir <- file.path(
  project_root, "results", "figures", "mechanisms_event_studies_controls"
)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

mechanisms <- build_mechanisms_panel(project_root)
panel <- mechanisms$panel
panel_controls <- mechanisms$panel_controls

estimate_event_study <- function(variable, estimator, xformla, data) {
  tryCatch({
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

    dynamic <- aggte(
      MP = model,
      type = "dynamic",
      min_e = -60,
      max_e = 60
    )

    tibble(
      time = dynamic$egt,
      estimate = dynamic$att.egt,
      std_error = dynamic$se.egt,
      variable = variable,
      estimator = estimator,
      conf_low = estimate - 1.96 * std_error,
      conf_high = estimate + 1.96 * std_error,
      status = "ok",
      error = NA_character_
    )
  }, error = function(error) {
    tibble(
      time = NA_real_,
      estimate = NA_real_,
      std_error = NA_real_,
      variable = variable,
      estimator = estimator,
      conf_low = NA_real_,
      conf_high = NA_real_,
      status = "error",
      error = conditionMessage(error)
    )
  })
}

estimate_pair <- function(variable) {
  bind_rows(
    estimate_event_study(variable, "CSDID", ~1, panel),
    estimate_event_study(
      variable,
      "CSDID (Controls)",
      ~PMASC18_ + VP_TV + VP_RADIO + PNOTRABA,
      panel_controls
    )
  )
}

family_results <- imap(mechanisms$families, function(outcomes, family) {
  message("Estimating event studies with controls comparison: ", family)
  map2_dfr(outcomes, seq_along(outcomes), function(variable, outcome_order) {
    estimate_pair(variable) |>
      mutate(outcome_order = outcome_order)
  }) |>
    mutate(
      family = family,
      outcome_label = mechanism_label(variable)
    )
})

all_results <- bind_rows(family_results)
saveRDS(
  all_results,
  file.path(rds_dir, "mechanisms_event_studies_with_controls.rds")
)

write.csv(
  all_results |> filter(status == "error") |>
    distinct(family, variable, estimator, error),
  file.path(rds_dir, "mechanisms_event_studies_with_controls_errors.csv"),
  row.names = FALSE
)

writeLines(
  mechanisms$skipped_outcomes,
  file.path(rds_dir, "skipped_zero_outcomes.txt")
)

iwalk(family_results, function(results, family) {
  plot_data <- results |>
    filter(
      status == "ok",
      if_all(c(estimate, conf_low, conf_high), is.finite)
    ) |>
    mutate(
      outcome_label = factor(
        outcome_label,
        levels = unique(outcome_label[order(outcome_order)])
      ),
      estimator = factor(estimator, levels = c("CSDID", "CSDID (Controls)"))
    )

  if (nrow(plot_data) == 0) {
    return(invisible(NULL))
  }

  plot <- ggplot(plot_data, aes(x = time, y = estimate, color = estimator)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(
      aes(ymin = conf_low, ymax = conf_high, fill = estimator),
      alpha = 0.16,
      color = NA
    ) +
    geom_line(linewidth = 0.35) +
    facet_wrap(vars(outcome_label), scales = "free_y", ncol = 3) +
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
      strip.text = element_text(size = 9),
      plot.caption = element_text(hjust = 0.5)
    ) +
    scale_x_continuous(expand = expansion(mult = c(0.03, 0.03)))

  rows <- ceiling(n_distinct(plot_data$outcome_label) / 3)
  ggsave(
    plot,
    filename = file.path(
      figure_dir,
      paste0(family, "_event_studies_with_controls.pdf")
    ),
    device = pdf,
    width = 11,
    height = max(4.5, rows * 3),
    units = "in",
    limitsize = FALSE
  )
})

