###################################################
## Descriptive Statistics: Federal and State Judicial Processing
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Required external input: annual judicial DBF directories
## Output: Federal and state processing trend figure
##
###################################################

pacman::p_load(tidyverse, foreign, purrr, patchwork)

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
raw_dir <- file.path(project_root, "data", "raw", "judicial", "sentencing")
figure_dir <- file.path(project_root, "results", "figures", "descriptives")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

judicial_file <- function(year, registry) {
  directory_parts <- if (year < 2003) {
    c(
      paste0("judiciales_bd_catalogos_", year, "_dbf"),
      paste0("judiciales_bd_catalogos_", year)
    )
  } else {
    paste0("Judiciales_BD_Catalogos_", year, "_dbf")
  }

  do.call(
    file.path,
    as.list(c(
      raw_dir,
      directory_parts,
      paste0("TablasMicrodatos_", year),
      paste0(registry, year, ".DBF")
    ))
  )
}

required_files <- unlist(lapply(
  1998:2012,
  function(year) c(
    judicial_file(year, "preg"),
    judicial_file(year, "sreg")
  )
))
missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0) {
  stop(
    paste(
      "Missing raw judicial DBF files. Add the annual directories under:",
      raw_dir,
      "First missing file:",
      missing_files[[1]],
      sep = "\n"
    ),
    call. = FALSE
  )
}
# Datasets used across all years

preprocess_judicial <- function(year){
  # Read all files
  if (year < 2003){
    inicio <- file.path(
      paste0('judiciales_bd_catalogos_', year, '_dbf'),
      paste0('judiciales_bd_catalogos_', year)
    )
  }else{
    inicio <- paste0('Judiciales_BD_Catalogos_', year, '_dbf')
  }
  preg <- read.dbf(
    file.path(raw_dir, inicio, paste0("TablasMicrodatos_", year),
              paste0("preg", year, ".DBF")),
    as.is = T
  ) # Registry: Processed
  sreg <- read.dbf(
    file.path(raw_dir, inicio, paste0("TablasMicrodatos_", year),
              paste0("sreg", year, ".DBF")),
    as.is = T
  ) # Registry: Sentenced 
  
  preg <- preg |> mutate(date_auto = as.Date(B_FAUTO), 
                         day = day(date_auto),
                         month = month(date_auto),
                         year = year(date_auto), 
                         month_year = paste0(year, '-', month), 
                         federal = ifelse(B_CVEESTAD == 42, 1, 0))
  
  sreg <- sreg |> mutate(date_auto = as.Date(B_FSENTEN), 
                         day = day(date_auto),
                         month = month(date_auto),
                         year = year(date_auto), 
                         month_year = paste0(year, '-', month), 
                         federal = ifelse(B_CVEESTAD == 52, 1, 0))
  
  final <- tibble(month = c(1:12)) |> mutate(year = year)
  
  pregf <- preg |> filter(federal == 1) |> group_by(year, month) |> 
    summarise(n_processed_f = n()) |> ungroup()
  
  pregs <- preg |> filter(federal == 0) |> group_by(year, month) |> 
    summarise(n_processed_s = n()) |> ungroup()
  
  sregf <- sreg |> filter(federal == 1) |> group_by(year, month) |> 
    summarise(n_sentenced_f = n()) |> ungroup()
  
  sregs <- sreg |> filter(federal == 0) |> group_by(year, month) |> 
    summarise(n_sentenced_s = n()) |> ungroup()
  
  final <- final |> left_join(pregf, by = c('month', 'year')) |> 
    left_join(pregs, by = c('month', 'year')) |> 
    left_join(sregf, by = c('month', 'year')) |> 
    left_join(sregs, by = c('month', 'year'))
  
  return(final)
}

dfall <- c(1998:2012) |>
  map_dfr(~preprocess_judicial(.x))

dfall <- dfall |> mutate(id_row = row_number(), 
                         month_year = paste0(year, '-', month))

# dfall <- dfall |> filter(!month %in% c(12, 1))

f <- ggplot(dfall, aes(x = id_row, y = n_processed_f)) +
  geom_line(linewidth = .6) +
  geom_point(size = 1) + 
  theme_bw() + 
  scale_x_continuous(
    breaks = seq(min(dfall$id_row), max(dfall$id_row), by = 12),
    labels = dfall$month_year[seq(1, max(dfall$id_row), by = 12)]
  ) +
  ylab("Federal") + 
  xlab("") +
  geom_vline(xintercept=109, color="black", linetype="dotted", 
             linewidth = 1) +
  geom_text(aes(x = 86, y = 4000), 
            label = "Start Calderon's tenure", color = "black", 
            size = 4, alpha = 1) +
  geom_smooth(method = "lm", formula = y ~ x + I(x^2), se = FALSE, 
              color = "black") +
  theme(
    axis.text.x = element_text(size = 10, colour = 'black'),      # X-axis tick labels (numbers)
    axis.title.x = element_text(size = 13), 
    axis.text.y = element_text(size = 10, colour = 'black'),      # X-axis tick labels (numbers)
    axis.title.y = element_text(size = 13) # X-axis title (e.g., "Event Time")
  )
d <- ggplot(dfall, aes(x = id_row, y = n_processed_s)) +
  geom_line(linewidth = .6) +
  geom_point(size = 1) + 
  theme_bw() + 
  scale_x_continuous(
    breaks = seq(min(dfall$id_row), max(dfall$id_row), by = 12),
    labels = dfall$month_year[seq(1, max(dfall$id_row), by = 12)]
  ) +
  geom_vline(xintercept=109, color="black", linetype="dotted", 
             linewidth = 1) +
  geom_smooth(method = "lm", formula = y ~ x + I(x^2), se = FALSE, 
              color = "black") +
  ylab("Local (State)") + 
  xlab("Date") +  
  theme(
    axis.text.x = element_text(size = 10, colour = 'black'),      # X-axis tick labels (numbers)
    axis.title.x = element_text(size = 13), 
    axis.text.y = element_text(size = 10, colour = 'black'),      # X-axis tick labels (numbers)
    axis.title.y = element_text(size = 13) # X-axis title (e.g., "Event Time")
  )
final <- (f) / (d)

ggsave(final, 
       filename = file.path(
         figure_dir, "federal_and_state_processing_trends.pdf"
       ),
       device = pdf, width = 9, height = 9, units = 'in')
