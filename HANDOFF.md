# Project Handoff

Last updated: 2026-06-12

## Current state

- Git is initialized on branch `main`.
- GitHub remote `origin` points to
  `https://github.com/ezagoc/prisions_replication.git`.
- The imported Dropbox materials are under `data/` and `overleaf/`.
- Analysis folders exist but do not yet contain scripts.
- The Overleaf remote has not been configured because its private Git URL is
  project-specific.

## Intended workflow

1. Code reads curated inputs from `data/final_datasets/`.
2. Code writes generated artifacts to `results/figures/` and
   `results/tables/`.
3. `make sync-results` mirrors those artifacts into the LaTeX tree.
4. Changes are committed and pushed to GitHub.
5. `make overleaf-push` publishes only `overleaf/` to the Overleaf Git remote.

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

## Handoff convention

Update this file whenever work pauses with an incomplete task. Record:

- what changed;
- commands or tests run;
- files still needing attention;
- assumptions that need confirmation.

