SHELL := /bin/sh

OVERLEAF_BRANCH ?= master

.PHONY: help status main-regressions main-graphs main-event-studies \
	main-event-studies-controls \
	main-att-results main-att-presentation main-att \
	mechanisms-event-studies mechanisms-event-studies-controls \
	mechanisms-att mechanisms \
	descriptive-capacity descriptive-table descriptive-panels \
	descriptive-maps descriptive-processing descriptives \
	sync-results overleaf-check overleaf-push

help:
	@printf '%s\n' \
		'make status         Show repository and remote status' \
		'make main-regressions Run the main event-study regressions' \
		'make main-graphs    Build the main event-study figures' \
		'make main-event-studies Run regressions and build figures' \
		'make main-event-studies-controls Compare event studies with controls' \
		'make main-att       Run the main ATT results and presentation figure' \
		'make mechanisms     Run mechanism event studies and ATTs' \
		'make mechanisms-event-studies-controls Compare mechanism event studies with controls' \
		'make descriptives   Run descriptives available from curated data' \
		'make descriptive-maps Run map-input preparation (requires raw workbook)' \
		'make descriptive-processing Run processing trends (requires raw DBFs)' \
		'make sync-results   Copy results into the Overleaf tree' \
		'make overleaf-check Verify that the Overleaf remote exists' \
		'make overleaf-push  Sync results and publish overleaf/ as a subtree'

status:
	@git status --short --branch
	@printf '\nRemotes:\n'
	@git remote -v

main-regressions:
	Rscript code/01-analysis/Run/main_event_studies_regressions.R

main-graphs:
	Rscript code/01-analysis/Graphs/main_event_studies_graphs.R

main-event-studies: main-regressions main-graphs

main-event-studies-controls:
	Rscript code/01-analysis/Run/main_event_studies_with_controls.R

main-att-results:
	Rscript code/01-analysis/Run/main_att_results.R

main-att-presentation:
	Rscript code/01-analysis/Graphs/main_att_presentation.R

main-att: main-att-results main-att-presentation

mechanisms-event-studies:
	Rscript code/01-analysis/Run/mechanisms_event_studies.R

mechanisms-event-studies-controls:
	Rscript code/01-analysis/Run/mechanisms_event_studies_with_controls.R

mechanisms-att:
	Rscript code/01-analysis/Run/mechanisms_att_results.R

mechanisms: mechanisms-event-studies mechanisms-att

descriptive-capacity:
	Rscript code/02-descriptives/descriptive_stats_capacity.R

descriptive-table:
	Rscript code/02-descriptives/descriptive_stats_table.R

descriptive-panels:
	Rscript code/02-descriptives/descriptive_stats_panel_did.R

descriptive-maps:
	Rscript code/02-descriptives/descriptive_stats_maps.R

descriptive-processing:
	Rscript code/02-descriptives/descriptive_stats_processed.R

descriptives: descriptive-capacity descriptive-table descriptive-panels

sync-results:
	@./scripts/sync-results.sh

overleaf-check:
	@git remote get-url overleaf >/dev/null 2>&1 || { \
		printf '%s\n' \
			'Missing Overleaf remote.' \
			'Add it with: git remote add overleaf <OVERLEAF_GIT_URL>'; \
		exit 1; \
	}

overleaf-push: overleaf-check sync-results
	@if test -n "$$(git status --porcelain -- overleaf)"; then \
		printf '%s\n' \
			'The Overleaf tree has uncommitted changes.' \
			'Commit them before publishing so the subtree contains the latest files.'; \
		exit 1; \
	fi
	git subtree push --prefix overleaf overleaf $(OVERLEAF_BRANCH)
