###################################################
## Descriptive Statistics: Prison Capacity and Overcrowding
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Output: Capacity and federal-prisoner trend figures
##
###################################################

pacman::p_load(tidyverse, arrow, purrr, patchwork)

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
figure_dir <- file.path(project_root, "results", "figures", "descriptives")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

monthly_conversion <- tibble(month = c(1:12)) |> 
  mutate(semester = ifelse(month %in% c(1:6), 1, 2), 
         bimonthly = case_when(month %in% c(1,2) ~ 1, 
                               month %in% c(3,4) ~ 2,
                               month %in% c(5,6) ~ 3,
                               month %in% c(7,8) ~ 4,
                               month %in% c(9,10) ~ 5,
                               month %in% c(11,12) ~ 6), 
         quarterly = case_when(month %in% c(1:4) ~ 1, 
                               month %in% c(5:8) ~ 2,
                               month %in% c(9:12) ~ 3))

dfini <- read_parquet(file.path(data_dir, "panel_capacity.parquet.gzip"))
dfini <- dfini |> mutate(perc_overcrowding = total_clean/capacity_clean, 
                         dummy_overcrowding = ifelse(overcrowding>0, 1, 0))

dfini <- dfini |> select(prison_id, year, month, center_name_clean, 
                         total_clean:relative_overcrowding, perc_overcrowding, 
                         dummy_overcrowding, min_dist_to_fed_km2) 

dfinig_base <- dfini |> group_by(year, month) |>
  summarise(total = sum(total_clean, na.rm = T),
            capacity = sum(capacity_clean, na.rm = T), .groups = 'drop') |>
  filter(year < 2013) |>
  mutate(id_row    = row_number(),
         over_cap  = (total / capacity) * 100,
         year_month = paste0(year, '-', month))

# Shared theme and x-axis scale to avoid repetition
cap_theme <- theme_bw() +
  theme(
    axis.text.x  = element_text(size = 10, colour = 'black', angle = 45, hjust = 1),
    axis.title.x = element_text(size = 13),
    axis.text.y  = element_text(size = 10, colour = 'black'),
    axis.title.y = element_text(size = 13),
    legend.position = 'bottom',
    legend.title = element_blank()
  )

x_scale <- scale_x_continuous(
  breaks = seq(min(dfinig_base$id_row), max(dfinig_base$id_row) + 1, by = 8),
  labels = dfinig_base$year_month[seq(1, max(dfinig_base$id_row) + 1, by = 8)]
)

# Panel A: Capacity vs Population
dfinig_long <- bind_rows(
  dfinig_base |> select(year, month, id_row, var = capacity) |> mutate(Variable = 'Capacity'),
  dfinig_base |> select(year, month, id_row, var = total)    |> mutate(Variable = 'Population')
)

f <- ggplot(dfinig_long, aes(x = id_row, y = var, color = Variable)) +
  geom_line(linewidth = .9) +
  geom_point(size = 1.2) +
  scale_color_manual(values = c("Capacity" = "black", "Population" = "grey50")) +
  x_scale +
  ylab("Number of inmates / capacity") +
  xlab("Date") +
  cap_theme

# Panel B: Percentage over-capacity
d <- ggplot(dfinig_base, aes(x = id_row, y = over_cap)) +
  geom_hline(yintercept = 100, linetype = 'dashed', colour = 'red', linewidth = .7) +
  geom_line(linewidth = .9) +
  geom_point(size = 1.2) +
  x_scale +
  ylab("% of capacity (population / capacity × 100)") +
  xlab("Date") +
  cap_theme

# Side-by-side layout
combined <- f + d + plot_annotation(tag_levels = 'A')

ggsave(combined,
       filename = file.path(figure_dir, "capacity_and_overcrowding.pdf"),
       device = pdf, width = 14, height = 6, units = 'in')

# Federal percentage out of total:

dfinig <- dfini |> group_by(year, month) |> 
  summarise(total = sum(total_clean, na.rm = T), 
            federal = sum(federal_clean, na.rm = T),
            ratio = (federal/total)*100)|> filter(year<2013) |> 
  ungroup() |>
  mutate(id_row = row_number()) |> 
  mutate(year_month = paste0(year, '-', month))

d <- ggplot(dfinig, aes(x = id_row, y = ratio)) +
  geom_line(linewidth = .9) +
  geom_point(size = 1.2) + 
  theme_bw() + 
  scale_x_continuous(
    breaks = seq(min(dfinig$id_row), max(dfinig$id_row)+1, by = 8),
    labels = dfinig$year_month[seq(1, max(dfinig$id_row)+1, by = 8)]
  ) +
  ylab("Percentage federal in state prisons") + 
  xlab("Date") +  
  theme(
    axis.text.x = element_text(size = 10, colour = 'black'),      # X-axis tick labels (numbers)
    axis.title.x = element_text(size = 13), 
    axis.text.y = element_text(size = 10, colour = 'black'),      # X-axis tick labels (numbers)
    axis.title.y = element_text(size = 13) # X-axis title (e.g., "Event Time")
  ) +
  scale_y_continuous(expand = expansion(mult = c(0.08, 0.08)))

ggsave(
  d,
  filename = file.path(figure_dir, "federal_share_in_state_prisons.pdf"),
  device = pdf,
  width = 8.22,
  height = 6.59,
  units = "in"
)

#### Some statistics: 

# Statistics on distance: 

dfinid <- dfini |> filter(year < 2013) |> 
  group_by(prison_id, year) |>
  summarise(min_dist_to_fed_km2 = min(min_dist_to_fed_km2, na.rm = T)) |>
  ungroup()

median(dfinid$min_dist_to_fed_km2)

dfinid2 <- dfini |> filter(year < 2013) |>
  group_by(prison_id) |>
  summarise(min_dist_to_fed_km2 = min(min_dist_to_fed_km2, na.rm = T)) |>
  ungroup()

median(dfinid2$min_dist_to_fed_km2)


dfinif <- dfini |> filter(year == 2012) |> 
  mutate(perc_federal = (federal_clean/total_clean) * 100) |>
  group_by(prison_id) |>
  summarise(
    perc_federal = ifelse(
      all(is.na(perc_federal)),
      NA_real_,
      max(perc_federal, na.rm = TRUE)
    ),
    .groups = "drop"
  ) |>
  ungroup()

dfinif <- dfinif |> filter(!is.na(perc_federal)) |> 
  mutate(dummy_0 = as.integer(perc_federal>0), 
         dummy_30 = as.integer(perc_federal>30))

# perc at least one federal prisoner: 
mean(dfinif$dummy_0)

# perc at least 30%: 
mean(dfinif$dummy_30)

# max perc:
max(dfinif$perc_federal)
