###################################################
## Main Results: ATT Presentation Figure
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Run before: main_att_results.R
## Output: Combined presentation figure
##
###################################################

pacman::p_load(tidyverse)

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
rds_dir <- file.path(project_root, "results", "rds", "main_att")
figure_dir <- file.path(project_root, "results", "figures", "main_att")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

pro <- readRDS(file.path(rds_dir, "processing_att_estimates.rds")) |>
  mutate(tipo = 'Pre-trial')

sent <- readRDS(file.path(rds_dir, "sentencing_att_estimates.rds")) |>
  mutate(tipo = 'Trial')

level_outcomes <- c(
  "free",
  "formal_prision",
  "total_processed",
  "sent_prison",
  "n_sentenced",
  "only_sent_money",
  "absolutoria"
)

both <- rbind(pro, sent) |>
  filter(
    type == "CSDID",
    variable %in% level_outcomes,
    if_all(c(estimate, conf.low, conf.high, conf.low1, conf.high1), is.finite)
  )

both <- both |> 
  mutate(Variable = case_when(variable == 'free' ~ 'log Released', 
                              variable == 'formal_prision' ~ 'log Pre-trial Detention', 
                              variable == 'total_processed' ~ 'log Total Processed', 
                              variable == 'sent_prison' ~ 'log Guilty (Prison)', 
                              variable == 'n_sentenced' ~ 'log Total Sentenced', 
                              variable == 'only_sent_money' ~ 'log Guilty (Money)',
                              variable == 'absolutoria' ~ 'log Not Guilty'))


both$Variable <- factor(both$Variable, 
                                 levels = c('log Guilty (Money)',
                                            'log Not Guilty',
                                            'log Guilty (Prison)',
                                            'log Total Sentenced',
                                            
                                            'log Pre-trial Detention',
                                            'log Released',  
                                            'log Total Processed'))

size_titles <- 11

results_plot <- ggplot(data = both, aes(x = estimate, y = factor(Variable))) + 
  geom_vline(xintercept = 0, linetype = "solid", color = "darkgrey", linewidth = .8) +
  geom_point(aes(shape = factor(tipo), color = factor(tipo)), size = 2, 
             position = position_dodge(width = 0.6)) +
  geom_errorbar(aes(xmin = conf.low1, xmax = conf.high1, 
                    color = factor(tipo)), position = position_dodge(width = 0.6), 
                width = 0.8, linetype = "solid") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high, 
                    color = factor(tipo)),
                position = position_dodge(width = 0.6), width = 0.4, 
                linetype = 'solid') +
  scale_shape_manual(values = c(4, 15, 16), name = 'Stage') +
  scale_color_manual(values = c("#57068C", "black"), name = 'Stage') +
  theme_bw() +  
  ylab("Variable") + 
  xlab("ATT with 95%-90% Confidence Interval") +
  theme(
    axis.text.x = element_text(size = size_titles, colour = 'black'),
    axis.title.x = element_text(size = size_titles), 
    axis.text.y = element_text(size = 11, colour = 'black'),
    axis.title.y = element_text(size = size_titles)
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.08, 0.08)))

ggsave(results_plot, 
       filename = file.path(figure_dir, "combined_att_presentation.pdf"),
       device = pdf, width = 8.22, height = 6.59, units = 'in')
