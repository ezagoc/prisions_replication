###################################################
## Main Results: Event-Study Graphs
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Run before: main_event_studies_regressions.R
## Output: Event study plots to results/figures/events_final/
##
###################################################

pacman::p_load(tidyverse, patchwork)

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
rds_dir <- file.path(project_root, "results", "rds", "main_event_studies")
figure_dir <- file.path(project_root, "results", "figures", "events_final")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# Load regression results

coefs_sent <- readRDS(file.path(rds_dir, "sentence_level_estimates.rds"))
cond <- readRDS(file.path(rds_dir, "conviction_rate_estimates.rds"))
sent_cond <- readRDS(
  file.path(rds_dir, "prison_given_conviction_rate_estimates.rds")
)
only_money <- readRDS(
  file.path(rds_dir, "monetary_sentence_rate_estimates.rds")
)
coefs_process <- readRDS(file.path(rds_dir, "processing_level_estimates.rds"))
formal <- readRDS(file.path(rds_dir, "pretrial_detention_rate_estimates.rds"))
free_rate <- readRDS(file.path(rds_dir, "release_rate_estimates.rds"))

# ── Shared theme ────────────────────────────────────────────────────────────────

size_titles <- 15
size_point  <- 0.6
ci_fill     <- "#4878CF"
ci_alpha    <- 0.35
line_width  <- 0.25
ylimb       <- 0.2
ylima       <- 0.42

theme_event <- function() {
  theme_classic() +
    theme(
      axis.text.x        = element_text(size = size_titles, colour = "black"),
      axis.title.x       = element_text(size = size_titles),
      axis.text.y        = element_text(size = size_titles, colour = "black"),
      axis.title.y       = element_text(size = size_titles),
      plot.title         = element_text(size = size_titles, hjust = 0.5, face = "bold"),
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
      legend.position    = "none"
    )
}

event_ylim <- function(data, padding = 0.08) {
  limits <- range(
    c(data$coef, data$ci_low, data$ci_up, 0),
    na.rm = TRUE
  )
  span <- diff(limits)
  margin <- ifelse(span > 0, span * padding, 0.05)

  c(limits[1] - margin, limits[2] + margin)
}

# ── Sentence levels ─────────────────────────────────────────────────────────────

n_sentenced_data <- coefs_sent |> filter(variable == 'n_sentenced')
sent_prison_data <- coefs_sent |> filter(variable == 'sent_prison')
only_sent_money_data <- coefs_sent |> filter(variable == 'only_sent_money')
absolutoria_data <- coefs_sent |> filter(variable == 'absolutoria')

p1 <- ggplot(data = n_sentenced_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Total Sentenced') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(n_sentenced_data)) +
  theme_event()

p2 <- ggplot(data = sent_prison_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Guilty (Prison)') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(sent_prison_data)) +
  theme_event()

p3 <- ggplot(data = only_sent_money_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Guilty (Money)') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(only_sent_money_data)) +
  theme_event()

p4 <- ggplot(data = absolutoria_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Not Guilty') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(absolutoria_data)) +
  theme_event()

final <- (p1 | p2) / (p3 | p4) +
  plot_annotation(
    caption = "Estimated coefficient (95% C.I.). Time relative to treatment (semesters)."
  ) &
  theme(plot.caption = element_text(size = 12, hjust = 0.5))

ggsave(final,
       filename = file.path(figure_dir, "sentence_levels_event_study.pdf"),
       device = pdf, width = 11, height = 8, units = 'in')


# ── Sentence rates / intensive margin ──────────────────────────────────────────

sent_intensive_data <- coefs_sent |> filter(variable == 'sent_intensive')

p1 <- ggplot(data = sent_intensive_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('Time Sentenced') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(sent_intensive_data)) +
  theme_event()

p2 <- ggplot(data = cond,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('Guilty / Sentenced') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(cond)) +
  theme_event()

p3 <- ggplot(data = sent_cond,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('Prison / Guilty') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(sent_cond)) +
  theme_event()

p4 <- ggplot(data = only_money,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('Money / Guilty') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(only_money)) +
  theme_event()

final <- (p1 | p2) / (p3 | p4) +
  plot_annotation(
    caption = "Estimated coefficient (95% C.I.). Time relative to treatment (semesters)."
  ) &
  theme(plot.caption = element_text(size = 12, hjust = 0.5))

ggsave(final,
       filename = file.path(figure_dir, "sentence_rates_event_study.pdf"),
       device = pdf, width = 11, height = 8, units = 'in')


# ── Process levels ──────────────────────────────────────────────────────────────

total_processed_data <- coefs_process |> filter(variable == 'total_processed')
formal_prision_data <- coefs_process |> filter(variable == 'formal_prision')
free_data <- coefs_process |> filter(variable == 'free')

p1 <- ggplot(data = total_processed_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Total Processed') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(total_processed_data)) +
  theme_event()

p2 <- ggplot(data = formal_prision_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Pre-trial Detention') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(formal_prision_data)) +
  theme_event()

p3 <- ggplot(data = free_data,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('log Released') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(free_data)) +
  theme_event()

final <- (p1 | p2) / (p3) +
  plot_annotation(
    caption = "Estimated coefficient (95% C.I.). Time relative to treatment (semesters)."
  ) &
  theme(plot.caption = element_text(size = 12, hjust = 0.5))

ggsave(final,
       filename = file.path(figure_dir, "processing_levels_event_study.pdf"),
       device = pdf, width = 11, height = 8, units = 'in')


# ── Process rates ───────────────────────────────────────────────────────────────

p1 <- ggplot(data = formal,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('Pre-trial Detention / Processed') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(formal)) +
  theme_event()

p2 <- ggplot(free_rate,
             mapping = aes(y = coef, x = time)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up), fill = ci_fill, alpha = ci_alpha) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(color = "black", linewidth = line_width) +
  geom_point(size = size_point, color = "black") +
  ggtitle('Free / Processed') +
  ylab('') +
  xlab('') +
  ylim(event_ylim(free_rate)) +
  theme_event()

final <- (p1) / (p2) +
  plot_annotation(
    caption = "Estimated coefficient (95% C.I.). Time relative to treatment (semesters)."
  ) &
  theme(plot.caption = element_text(size = 12, hjust = 0.5))

ggsave(final,
       filename = file.path(figure_dir, "processing_rates_event_study.pdf"),
       device = pdf, width = 9, height = 9, units = 'in')
