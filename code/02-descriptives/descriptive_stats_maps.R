###################################################
## Descriptive Statistics: Prison Map Inputs
## Author: Eduardo Zago-Cuevas (all errors are my own)
## Required external input: data/raw/maps/prisiones_federales.xlsx
##
###################################################

pacman::p_load(tidyverse, arrow, purrr, readxl)

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
federal_prisons_file <- file.path(
  project_root, "data", "raw", "maps", "prisiones_federales.xlsx"
)

if (!file.exists(federal_prisons_file)) {
  stop(
    paste(
      "Missing federal-prisons workbook. Add it at:",
      federal_prisons_file
    ),
    call. = FALSE
  )
}

dfini <- read_parquet(file.path(data_dir, "panel_capacity.parquet.gzip"))

fed <- read_excel(federal_prisons_file) |> 
  select(name, date_opening, latitude, longitude, capacity, private, closed) |>
  mutate(date_opening = as.Date(date_opening))

prisd <- read_parquet(
  file.path(data_dir, "individual_prisons_municipalities.parquet.gzip")
)

dfini2 <- dfini |> select(prison_id)
