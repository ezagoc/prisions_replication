# Prisons Replication

Replication repository for the project **Capacity Constraints, Case-load
Increases and Incarceration Rates: Evidence from Prison Constructions**.

The repository connects three parts of the project:

- analysis code and curated replication data;
- generated figures and tables;
- the LaTeX source published to Overleaf.

## Repository layout

```text
code/
  00-processing/   Data preparation
  01-analysis/     Main and robustness analyses
  02-descriptives/ Descriptive statistics and graphics
data/
  final_datasets/  Curated analysis-ready inputs tracked by Git
results/
  figures/         Generated figures
  tables/          Generated tables
overleaf/          Paper and presentation LaTeX source
scripts/           Project maintenance scripts
```

`results/` is the canonical location for generated outputs. Running
`make sync-results` copies those outputs into `overleaf/figures/` and
`overleaf/tables/`, where the paper can include them.

## Getting started

```bash
git clone https://github.com/ezagoc/prisions_replication.git
cd prisions_replication
make status
```

Run the analysis using the scripts in `code/`, then synchronize the generated
paper assets:

```bash
make sync-results
```

## Overleaf workflow

The GitHub repository is the source of truth. The `overleaf/` directory is
published as a subtree so that `main.tex` remains at the root of the Overleaf
project.

Add the project's Overleaf Git URL once:

```bash
git remote add overleaf <OVERLEAF_GIT_URL>
```

Then publish:

```bash
make overleaf-push
```

The publish target deliberately stops if `overleaf/` has uncommitted changes.
This prevents a subtree push from sending an older version of generated
figures or tables.

The target branch defaults to `master`, which can be overridden:

```bash
make overleaf-push OVERLEAF_BRANCH=main
```

Before pushing, verify that `overleaf/main.tex` points to the correct draft
directory. See [HANDOFF.md](HANDOFF.md) for current project state and known
issues.

## Data policy

Only analysis-ready replication inputs belong in `data/final_datasets/`.
Raw, confidential, licensed, or easily regenerated intermediate data should
not be committed. The corresponding locations are ignored by Git.

## Routine

```bash
git pull --rebase origin main
# edit code and run analyses
make sync-results
git add code data/final_datasets results overleaf
git commit -m "Describe the analysis update"
git push origin main
make overleaf-push
```
