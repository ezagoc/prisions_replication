#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

sync_directory() {
	source_dir=$1
	target_dir=$2

	mkdir -p "$source_dir" "$target_dir"
	rsync -a --delete \
		--exclude '.DS_Store' \
		--exclude '.gitkeep' \
		"$source_dir/" "$target_dir/"
}

sync_directory "$root/results/figures" "$root/overleaf/figures"
sync_directory "$root/results/tables" "$root/overleaf/tables"

printf '%s\n' "Synchronized results into overleaf/."
