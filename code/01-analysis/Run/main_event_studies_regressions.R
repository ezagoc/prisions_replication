###################################################
## Main Results: Event-Study Regressions
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Output: Regression coefficients saved to results/rds/main_event_studies/
##
###################################################

pacman::p_load(tidyverse, arrow, purrr, did)

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
output_dir <- file.path(project_root, "results", "rds", "main_event_studies")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Judicial data

p1 <- read_parquet(file.path(data_dir, "panel_comun_1997_2008.parquet.gzip")) |>
  filter(year > 1999)

p2 <- read_parquet(file.path(data_dir, "panel_comun_2009_2012.parquet.gzip"))

p <- bind_rows(p1, p2)

dfini <- read_parquet(file.path(data_dir, "treatment_judicial.parquet.gzip"))

controls <- read_parquet(file.path(data_dir, "controls.parquet.gzip")) |>
  select(code_inegi, POBTOT:PHOGJEFF) |>
  mutate(across(c(POBTOT:PHOGJEFF), ~log(.x+1)))

# Panel construction

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

p <- p |> left_join(monthly_conversion)

p <- p |> select(code_inegi, CVE_ENT, year, semester,
                 crime_5, sent_prison, total_processed, formal_prision, free,
                 sent_intensive, sent_intensive_incl, n_sentenced, only_sent_money,
                 absolutoria, condenado
) |>
  group_by(code_inegi, year, semester) |>
  summarise(across(c(total_processed, sent_prison, formal_prision, free,
                     sent_intensive, sent_intensive_incl, n_sentenced,
                     only_sent_money, absolutoria, condenado), ~sum(.x))) |>
  ungroup() |> rename(actual_time = semester)

p <- p |> mutate(rate_free = ifelse(total_processed != 0,
                                    free/total_processed, 0),
                 processed_0 = as.integer(total_processed == 0),
                 rate_formal = ifelse(total_processed != 0,
                                      formal_prision/total_processed, 0),
                 sent_intensive = log(ifelse(n_sentenced != 0,
                                             sent_intensive_incl/n_sentenced, 0)+1),
                 rate_sent_cond = ifelse(condenado != 0,
                                         sent_prison/condenado, 0),
                 rate_cond = ifelse(n_sentenced != 0,
                                    condenado/n_sentenced, 0),
                 rate_only_money = ifelse(condenado != 0,
                                          only_sent_money/condenado, 0),
                 condenado_0 = as.integer(condenado == 0),
                 sentenced_0 = as.integer(n_sentenced == 0),
                 n_sentenced = log(n_sentenced + 1),
                 sent_prison = log(sent_prison + 1),
                 total_processed = log(total_processed + 1),
                 formal_prision = log(formal_prision + 1),
                 free = log(free + 1),
                 only_sent_money = log(only_sent_money + 1),
                 absolutoria = log(absolutoria + 1)
)

treat_post_p <- 'btreat_300KM2'

dfini <- dfini |> left_join(monthly_conversion) |> 
  select(code_inegi, year, semester, btreat_300KM2) |>
  group_by(code_inegi, year, semester) |> 
  summarise(btreat_300KM2 = max(btreat_300KM2, na.rm=T)) |>
  ungroup()

p <- p |> left_join(dfini,
                    by = c('code_inegi', 'year', 'actual_time'='semester'))

time <- p |> distinct(year, actual_time) |> mutate(m_time = row_number())

p <- p |> left_join(time, by = c('year', 'actual_time'))

p <- p |> mutate(treat_post := .data[[treat_post_p]])

p <- p |> group_by(code_inegi) |>
  mutate(event_time = m_time[treat_post > 0][1],
         treat = ifelse(is.na(event_time) == F, 1, 0)) |>
  ungroup()

p$event_time[p$treat == 0] <- 0

p <- p %>% group_by(code_inegi) %>%
  mutate(time_to_event = ifelse(treat == 1, m_time - event_time, 0),
         time_to_event_gard = ifelse(treat == 1, m_time - event_time, Inf)) |>
  ungroup()

pcont <- p |> left_join(controls)

# Functions

funct_event <- function(variable){

  cs21 = att_gt(yname = variable, tname = "m_time", idname = "code_inegi",
                gname = "event_time",
                xformla = ~ PMASC18_ + VP_TV + VP_RADIO + PNOTRABA,
                control_group = "nevertreated",
                clustervars = "code_inegi",
                data = pcont)

  cs_event <- aggte(MP = cs21, type = "dynamic", min_e = -60, max_e = 60)

  df_call <- tibble(time = cs_event$egt, coef = cs_event$att.egt,
                    se = cs_event$se.egt, variable = variable,
                    ci_low = coef - se*(qnorm(1-(1-0.95)/2)),
                    ci_up = coef + se*(qnorm(1-(1-0.95)/2)),
                    ci_low1 = coef - se*(qnorm(1-(1-0.90)/2)),
                    ci_up1 = coef + se*(qnorm(1-(1-0.90)/2)))

  return(df_call)
}

funct_events_rate <- function(variable, control){

  cs21 = att_gt(yname = variable, tname = "m_time", idname = "code_inegi",
                gname = "event_time",
                xformla = as.formula(paste0('~ PMASC18_ + VP_TV + VP_RADIO + PNOTRABA + ',
                                            control)),
                control_group = "nevertreated",
                clustervars = "code_inegi",
                data = pcont)

  cs_event <- aggte(MP = cs21, type = "dynamic", min_e = -60, max_e = 60)

  df_call <- tibble(time = cs_event$egt, coef = cs_event$att.egt,
                    se = cs_event$se.egt, variable = variable,
                    ci_low = coef - se*(qnorm(1-(1-0.95)/2)),
                    ci_up = coef + se*(qnorm(1-(1-0.95)/2)),
                    ci_low1 = coef - se*(qnorm(1-(1-0.90)/2)),
                    ci_up1 = coef + se*(qnorm(1-(1-0.90)/2)))

  return(df_call)
}

# Run regressions

coefs_sent <- c('only_sent_money','absolutoria', 'sent_prison', 'sent_intensive',
                'n_sentenced') |>
  map_dfr(~funct_event(.x)) |>
  mutate(Variable = case_when(variable == 'sent_prison' ~ 'log Guilty (Prison)',
                              variable == 'n_sentenced' ~ 'log Total Sentenced',
                              variable == 'only_sent_money' ~ 'log Guilty (Money)',
                              variable == 'absolutoria' ~ 'log Not Guilty',
                              variable == 'sent_intensive' ~ 'Time Sentenced',
                              variable == 'rate_cond' ~ 'Guilty / sentenced',
                              variable == 'rate_sent_cond' ~ 'Prison / guilty',
                              variable == 'rate_only_money' ~ 'Money / guilty'))

cond      <- funct_events_rate('rate_cond', 'sentenced_0')
sent_cond <- funct_events_rate('rate_sent_cond', 'condenado_0')
only_money <- funct_events_rate('rate_only_money', 'condenado_0')

coefs_process <- c('total_processed', 'formal_prision', 'free') |>
  map_dfr(~funct_event(.x))

formal    <- funct_events_rate('rate_formal', 'processed_0')
free_rate <- funct_events_rate('rate_free', 'processed_0')

# Save results

saveRDS(coefs_sent, file.path(output_dir, "sentence_level_estimates.rds"))
saveRDS(cond, file.path(output_dir, "conviction_rate_estimates.rds"))
saveRDS(
  sent_cond,
  file.path(output_dir, "prison_given_conviction_rate_estimates.rds")
)
saveRDS(
  only_money,
  file.path(output_dir, "monetary_sentence_rate_estimates.rds")
)
saveRDS(coefs_process, file.path(output_dir, "processing_level_estimates.rds"))
saveRDS(formal, file.path(output_dir, "pretrial_detention_rate_estimates.rds"))
saveRDS(free_rate, file.path(output_dir, "release_rate_estimates.rds"))
