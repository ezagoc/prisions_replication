SHELL := /bin/sh

OVERLEAF_BRANCH ?= master

.PHONY: help status sync-results overleaf-check overleaf-push

help:
	@printf '%s\n' \
		'make status         Show repository and remote status' \
		'make sync-results   Copy results into the Overleaf tree' \
		'make overleaf-check Verify that the Overleaf remote exists' \
		'make overleaf-push  Sync results and publish overleaf/ as a subtree'

status:
	@git status --short --branch
	@printf '\nRemotes:\n'
	@git remote -v

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
