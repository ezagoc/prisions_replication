###################################################
## Capacity First Stage: Relative Overcrowding
## Output: First-stage figures for the final paper
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
rds_dir <- file.path(project_root, "results", "rds", "capacity_first_stage")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

df_base <- read_parquet(file.path(data_dir, "panel_capacity.parquet.gzip")) |>
  mutate(
    perc_overcrowding = total_clean / capacity_clean,
    dummy_overcrowding = if_else(overcrowding > 0, 1, 0)
  )

prison_id <- df_base |>
  distinct(prison_id) |>
  mutate(prison_id_num = row_number())

time_index <- df_base |>
  distinct(year, month) |>
  arrange(year, month) |>
  mutate(bim_time = row_number())

df_base <- df_base |>
  left_join(prison_id, by = "prison_id") |>
  left_join(time_index, by = c("year", "month"))

run_cs <- function(df_base, treatment_var, radius_label) {
  df <- df_base |>
    mutate(
      treat_post = .data[[treatment_var]] * federal_p50,
      relative_overcrowding_asinh = asinh(relative_overcrowding)
    ) |>
    group_by(prison_id) |>
    mutate(
      event_time = {
        treated_periods <- bim_time[treat_post > 0]
        if (length(treated_periods) == 0) 0 else treated_periods[[1]]
      },
      treat = as.integer(event_time > 0)
    ) |>
    ungroup()

  model <- att_gt(
    yname = "relative_overcrowding_asinh",
    tname = "bim_time",
    idname = "prison_id_num",
    gname = "event_time",
    control_group = "nevertreated",
    clustervars = "prison_id_num",
    allow_unbalanced_panel = TRUE,
    data = df
  )

  dynamic <- aggte(MP = model, type = "dynamic", min_e = -60, max_e = 60)
  simple <- aggte(MP = model, type = "simple")

  tibble(
    time = dynamic$egt,
    estimate = dynamic$att.egt,
    std_error = dynamic$se.egt,
    conf_low = estimate - 1.96 * std_error,
    conf_high = estimate + 1.96 * std_error,
    radius = radius_label,
    treatment_var = treatment_var,
    overall_att = simple$overall.att,
    overall_se = simple$overall.se
  )
}

theme_event <- function() {
  theme_classic(base_size = 10) +
    theme(
      axis.text = element_text(color = "black"),
      panel.grid.major.y = element_line(color = "grey88", linewidth = 0.25),
      legend.position = "bottom",
      legend.title = element_blank()
    )
}

plot_event <- function(data, filename, overlay = FALSE) {
  dodge <- position_dodge(width = 0.7)

  plot <- ggplot(data, aes(x = time, y = estimate, color = radius)) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "grey50", linetype = "dashed", linewidth = 0.3) +
    geom_errorbar(
      aes(ymin = conf_low, ymax = conf_high),
      width = 0,
      linewidth = 0.25,
      position = dodge
    ) +
    geom_point(aes(shape = radius), size = 1.05, position = dodge) +
    scale_color_manual(
      values = c("400 km" = "black", "300 km" = "grey72", "500 km" = "#2F6FB3")
    ) +
    scale_shape_manual(values = c("400 km" = 16, "300 km" = 17, "500 km" = 15)) +
    labs(
      x = "Bimonths since federal prison opening",
      y = "Estimated effect on asinh(relative overcrowding)"
    ) +
    theme_event()

  if (!overlay) {
    plot <- plot + theme(legend.position = "none")
  }

  ggsave(
    plot,
    filename = file.path(figure_dir, filename),
    device = pdf,
    width = 7.2,
    height = 4.6,
    units = "in"
  )
}

capacity_estimates <- bind_rows(
  run_cs(df_base, "btreat_400KM2", "400 km"),
  run_cs(df_base, "btreat_300KM2", "300 km"),
  run_cs(df_base, "btreat_500KM2", "500 km")
)

saveRDS(
  capacity_estimates,
  file.path(rds_dir, "capacity_first_stage_event_studies.rds")
)

plot_event(
  capacity_estimates |> filter(radius == "400 km"),
  "capacity_first_stage_400km.pdf"
)

plot_event(
  capacity_estimates |> filter(radius %in% c("300 km", "500 km")),
  "capacity_first_stage_robustness.pdf",
  overlay = TRUE
)

att_table <- capacity_estimates |>
  distinct(radius, treatment_var, overall_att, overall_se) |>
  arrange(match(radius, c("300 km", "400 km", "500 km"))) |>
  mutate(
    conf_low = overall_att - 1.96 * overall_se,
    conf_high = overall_att + 1.96 * overall_se
  )

write.csv(
  att_table,
  file.path(table_dir, "capacity_first_stage_att.csv"),
  row.names = FALSE
)

print(att_table)
message("Capacity first-stage figures written to: ", figure_dir)
