###################################################
## Mechanisms: Average Treatment Effects
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Output: Mechanism ATT estimates and figures
###################################################

pacman::p_load(fixest)

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

rds_dir <- file.path(project_root, "results", "rds", "mechanisms_att")
figure_dir <- file.path(project_root, "results", "figures", "mechanisms_att")
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

mechanisms <- build_mechanisms_panel(project_root)
panel <- mechanisms$panel
panel_controls <- mechanisms$panel_controls

result_row <- function(variable, estimator, estimate, std_error) {
  tibble(
    variable = variable,
    estimator = estimator,
    estimate = estimate,
    std_error = std_error,
    conf_low = estimate - 1.96 * std_error,
    conf_high = estimate + 1.96 * std_error,
    conf_low_90 = estimate - 1.645 * std_error,
    conf_high_90 = estimate + 1.645 * std_error,
    status = "ok",
    error = NA_character_
  )
}

error_row <- function(variable, estimator, error) {
  tibble(
    variable = variable,
    estimator = estimator,
    estimate = NA_real_,
    std_error = NA_real_,
    conf_low = NA_real_,
    conf_high = NA_real_,
    conf_low_90 = NA_real_,
    conf_high_90 = NA_real_,
    status = "error",
    error = conditionMessage(error)
  )
}

estimate_twfe <- function(variable) {
  tryCatch({
    model <- feols(
      as.formula(paste0(variable, " ~ treat_post | code_inegi + m_time")),
      cluster = "code_inegi",
      data = panel
    )
    result_row(
      variable,
      "TWFE",
      unname(coef(model)[["treat_post"]]),
      unname(se(model)[["treat_post"]])
    )
  }, error = function(error) error_row(variable, "TWFE", error))
}

estimate_csdid <- function(variable, controls = FALSE) {
  estimator <- if (controls) "CSDID (Controls)" else "CSDID"
  data <- if (controls) panel_controls else panel
  formula <- if (controls) {
    ~PMASC18_ + VP_TV + VP_RADIO + PNOTRABA
  } else {
    ~1
  }

  tryCatch({
    model <- att_gt(
      yname = variable,
      tname = "m_time",
      idname = "code_inegi",
      gname = "event_time",
      xformla = formula,
      control_group = "nevertreated",
      clustervars = "code_inegi",
      data = data
    )
    aggregate <- aggte(MP = model, type = "simple")
    result_row(
      variable,
      estimator,
      aggregate$overall.att,
      aggregate$overall.se
    )
  }, error = function(error) error_row(variable, estimator, error))
}

estimate_att <- function(variable) {
  bind_rows(
    estimate_twfe(variable),
    estimate_csdid(variable),
    estimate_csdid(variable, controls = TRUE)
  )
}

family_results <- imap(mechanisms$families, function(outcomes, family) {
  message("Estimating ATTs: ", family)
  map2_dfr(outcomes, seq_along(outcomes), function(variable, outcome_order) {
    estimate_att(variable) |>
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
  file.path(rds_dir, "mechanisms_att_estimates.rds")
)

write.csv(
  all_results |> filter(status == "error") |>
    distinct(family, variable, estimator, error),
  file.path(rds_dir, "mechanisms_att_errors.csv"),
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
      if_all(
        c(estimate, conf_low, conf_high, conf_low_90, conf_high_90),
        is.finite
      )
    ) |>
    mutate(
      estimator = factor(
        estimator,
        levels = c("TWFE", "CSDID", "CSDID (Controls)")
      ),
      outcome_label = factor(
        outcome_label,
        levels = unique(outcome_label[order(outcome_order)])
      )
    )

  if (nrow(plot_data) == 0) {
    return(invisible(NULL))
  }

  plot <- ggplot(
    plot_data,
    aes(x = estimate, y = outcome_label, shape = estimator)
  ) +
    geom_vline(xintercept = 0, color = "grey60") +
    geom_errorbar(
      aes(xmin = conf_low, xmax = conf_high),
      position = position_dodge(width = 0.6),
      width = 0.3
    ) +
    geom_errorbar(
      aes(xmin = conf_low_90, xmax = conf_high_90),
      position = position_dodge(width = 0.6),
      width = 0.55,
      linewidth = 0.8
    ) +
    geom_point(position = position_dodge(width = 0.6), size = 2) +
    scale_shape_manual(values = c(4, 15, 16), name = "Estimator") +
    labs(
      x = "ATT with 95% and 90% confidence intervals",
      y = NULL
    ) +
    theme_bw() +
    theme(legend.position = "bottom") +
    scale_x_continuous(expand = expansion(mult = c(0.08, 0.08)))

  rows <- n_distinct(plot_data$outcome_label)
  ggsave(
    plot,
    filename = file.path(figure_dir, paste0(family, "_att.pdf")),
    device = pdf,
    width = 9,
    height = max(4.5, rows * 0.45),
    units = "in",
    limitsize = FALSE
  )
})
