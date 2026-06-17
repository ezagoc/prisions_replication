###################################################
## Mechanisms: Event Studies
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Output: Mechanism event-study estimates and figures
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
  project_root, "results", "rds", "mechanisms_event_studies"
)
figure_dir <- file.path(
  project_root, "results", "figures", "mechanisms_event_studies"
)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

mechanisms <- build_mechanisms_panel(project_root)
panel_controls <- mechanisms$panel_controls

estimate_event_study <- function(variable) {
  tryCatch({
    model <- att_gt(
      yname = variable,
      tname = "m_time",
      idname = "code_inegi",
      gname = "event_time",
      xformla = ~PMASC18_ + VP_TV + VP_RADIO + PNOTRABA,
      control_group = "nevertreated",
      clustervars = "code_inegi",
      data = panel_controls
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
      conf_low = NA_real_,
      conf_high = NA_real_,
      status = "error",
      error = conditionMessage(error)
    )
  })
}

family_results <- imap(mechanisms$families, function(outcomes, family) {
  message("Estimating event studies: ", family)
  map_dfr(outcomes, estimate_event_study) |>
    mutate(
      family = family,
      outcome_label = mechanism_label(variable)
    )
})

all_results <- bind_rows(family_results)
saveRDS(
  all_results,
  file.path(rds_dir, "mechanisms_event_study_estimates.rds")
)

write.csv(
  all_results |> filter(status == "error") |>
    distinct(family, variable, error),
  file.path(rds_dir, "mechanisms_event_study_errors.csv"),
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
    )

  if (nrow(plot_data) == 0) {
    return(invisible(NULL))
  }

  plot <- ggplot(plot_data, aes(x = time, y = estimate)) +
    geom_ribbon(
      aes(ymin = conf_low, ymax = conf_high),
      fill = "#4878CF",
      alpha = 0.3
    ) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_line(linewidth = 0.35) +
    facet_wrap(vars(outcome_label), scales = "free_y", ncol = 3) +
    labs(
      x = "Time relative to treatment (semesters)",
      y = "Estimated effect",
      caption = "Shaded areas are 95% confidence intervals."
    ) +
    theme_bw() +
    theme(
      strip.text = element_text(size = 9),
      plot.caption = element_text(hjust = 0.5)
    ) +
    scale_x_continuous(expand = expansion(mult = c(0.03, 0.03)))

  rows <- ceiling(n_distinct(plot_data$outcome_label) / 3)
  ggsave(
    plot,
    filename = file.path(
      figure_dir,
      paste0(family, "_event_studies.pdf")
    ),
    device = pdf,
    width = 11,
    height = max(4.5, rows * 3),
    units = "in",
    limitsize = FALSE
  )
})

