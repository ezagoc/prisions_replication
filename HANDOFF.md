# Project Handoff

Last updated: 2026-06-12

## Current state

- Git is initialized on branch `main`.
- GitHub remote `origin` points to
  `https://github.com/ezagoc/prisions_replication.git`.
- The imported Dropbox materials are under `data/` and `overleaf/`.
- Main event-study scripts are
  `code/01-analysis/Run/main_event_studies_regressions.R` and
  `code/01-analysis/Graphs/main_event_studies_graphs.R`.
- The event-study comparison with and without controls is
  `code/01-analysis/Run/main_event_studies_with_controls.R`.
- Main ATT scripts are `code/01-analysis/Run/main_att_results.R` and
  `code/01-analysis/Graphs/main_att_presentation.R`.
- Mechanisms scripts are `code/01-analysis/Run/mechanisms_event_studies.R`
  and `code/01-analysis/Run/mechanisms_att_results.R`, with shared panel
  construction in `code/01-analysis/Run/mechanisms_helpers.R`.
- Mechanism event-study comparisons with and without controls are in
  `code/01-analysis/Run/mechanisms_event_studies_with_controls.R`.
- Descriptive scripts are under `code/02-descriptives/`.
- The Overleaf remote has not been configured because its private Git URL is
  project-specific.

## Intended workflow

1. Code reads curated inputs from `data/final_datasets/`.
2. Main event-study regressions write RDS objects to
   `results/rds/main_event_studies/`.
3. Main event-study graphs write PDFs to `results/figures/events_final/`.
4. When the Overleaf workflow is ready, `make sync-results` mirrors generated
   figures and tables into the LaTeX tree.
5. Changes are committed and pushed to GitHub.
6. `make overleaf-push` publishes only `overleaf/` to the Overleaf Git remote.

## Known issue

`overleaf/main.tex` and `overleaf/v3_draft/main.tex` define
`\prisonversion` as `v3`, then include files from `v3_prisons/`. The imported
directory is currently named `v3_draft/`. The main document will not compile
until the intended directory name or LaTeX path is confirmed and made
consistent.

## Next steps

- Confirm whether `v3_draft/` should be renamed to `v3_prisons/`, or update
  the LaTeX includes.
- Add the Overleaf remote using the project's Git URL.
- Place analysis scripts in the numbered `code/` directories.
- Ensure scripts write stable filenames under `results/`.
- Record software versions and a full reproduction command once the analysis
  environment is restored.

## Main event studies

Run the complete pipeline from the repository root:

```bash
make main-event-studies
```

The `did` estimator currently reports that 390 rows are dropped because of
missing covariate data. This warning is consistent across the event-study
outcomes and should be reviewed before final replication release.

Run the comparison between uncontrolled CSDID and controlled CSDID event
studies with:

```bash
make main-event-studies-controls
```

Outputs are written to `results/rds/main_event_studies_controls/` and
`results/figures/main_event_studies_controls/`.

## Main ATT results

Run the ATT estimates and figures from the repository root:

```bash
make main-att
```

Outputs are written to `results/rds/main_att/` and
`results/figures/main_att/`.

The ATT estimator reports that 69 units were already treated in the first
period and that 390 rows were dropped because of missing covariate data. Both
sample restrictions should be reviewed before the final replication release.

## Mechanisms

Run all interaction-panel mechanisms:

```bash
make mechanisms
```

Run the mechanism event-study comparison between uncontrolled CSDID and
controlled CSDID with:

```bash
make mechanisms-event-studies-controls
```

The pipeline estimates 92 outcomes in nine families. Event-study
results are written to `results/rds/mechanisms_event_studies/` and
`results/figures/mechanisms_event_studies/`. ATT results are written to
`results/rds/mechanisms_att/` and `results/figures/mechanisms_att/`.

Crime category 14 is excluded by design, and category 11 is not requested
because it is zero throughout the interaction panels. All requested event
studies and all 276 ATT estimates completed successfully.

## Descriptive analyses

Run the descriptive analyses that use curated data:

```bash
make descriptives
```

Outputs are written to `results/figures/descriptives/` and
`results/tables/descriptives/`.

Missing external inputs:

- Add the federal-prisons workbook at
  `data/raw/maps/prisiones_federales.xlsx`.
- Add annual judicial DBF directories for 1998-2012 under
  `data/raw/judicial/sentencing/`. For example, the first expected file is
  `data/raw/judicial/sentencing/judiciales_bd_catalogos_1998_dbf/judiciales_bd_catalogos_1998/TablasMicrodatos_1998/preg1998.DBF`.

`descriptive_stats_maps.R` currently loads and selects map inputs but does not
yet contain the code that constructs or saves a map.

## Handoff convention

Update this file whenever work pauses with an incomplete task. Record:

- what changed;
- commands or tests run;
- files still needing attention;
- assumptions that need confirmation.
