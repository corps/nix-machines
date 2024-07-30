include maketools/help.mk

project_directories:=$(sort $(dir $(wildcard ./*/Makefile)))
image_directories:=$(filter $(sort $(dir $(wildcard ./*/Dockerfile))), $(project_directories))
nix_directories:=$(filter $(sort $(dir $(wildcard ./*/default.nix))), $(project_directories))

help::
	@for project in $(project_directories); do printf "* \033[1;32m-C $${project}\033[00m:\n$$(make -C $$project help)\n"; done

test::
	echo safe
