default: help

.PHONY: help
help:: # Displays this help message
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z0-9 -]+(:+).*#' | sort | while read -r l; do printf "* \033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done
