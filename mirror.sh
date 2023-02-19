#!/bin/bash

# Copyright (c) 2023 Florian Kutzer <info@florian-kutzer.de>
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# load configfile
source ./config.sh

# WIP load config from Environment variables if set.
# WIP remove trailing slash from mirror dir if set.
# load config
function load_config() {
	# check if a different config location is specified
	if [ -z "$1" ]
	then
		# load default location if not specified
		# WIP follof XDG_CONFIG_HOME
		source "./config.sh"
	else
		source "$1"
	fi
}

# set default variables if not set in config
function set_default() {
	# set git_path if not set in config
	if [ -z "$git_path" ]
	then
		git_path="git"
	fi

	# set mirror_store if not set
	if [ -z "$mirror_store" ]
	then
		mirror_store="./mirror"
	fi
}

# create mirror root dir
function create_mirror_root() {
	# check if mirrordir exist and create it if needed
	if [ ! -e "$mirror_store" ]
	then
		mkdir -p "$mirror_store"
	fi
}

# check repo
function check_repo() {
	# check if repo is provided
	if [ -z "$1" ]
	then
		echo "No repo provided"
		return 1
	fi

	repo="$1"


	# build origin variable for repo
	rep_origin="${repo}_origin"

	# check if origin is set
	if [ -z "${!rep_origin}" ]
	then
		echo "No origin set for $repo"
		return 1
	fi

	# build clones variable for repo
	rep_clones="${repo}_clones"

	# check if clones are set
	if [ -z "${!rep_clones}" ]
	then
		echo "No clones set for $repo"
		return 1
	fi
}

# check if config for repos is correct
function check_config() {
	# check if active repos are configured
	if [ -z "$active" ]
	then
		echo "No repos specified"
		return 1
	else
		# check all active repos
		for repo in "${active[@]}"
		do
			check_repo "$repo"
		done

	fi
}

# mirror_repo mirros the repo to another repo.
# takes the configname as the first, origin as second and an array of destinations
# as a third argument.
# the array is passed by name to keep the values
function mirror_repo() {
	# check if configname is supplied
	if [ -z "$1" ]
	then
		echo "No configname supplied"
		return 1
	fi

	configname="$1"
	

	# check if repos is supplied
	if [ -z "$2" ]
	then
		echo "No repo supplied"
		return 1
	fi

	repo="$2"

	# check if destinations are supplied
	if [ -z "$3" ]
	then
		echo "No destination supplied"
		return 1
	fi

	# copy destinations
	dest_temp="$3[@]"
	destinations=("${!dest_temp}")
	
	# build the destination path
	destination_dir="${mirror_store}/${configname}"

	# create directory for local mirror if needed
	if [ ! -e "$destination_dir" ]
	then
		mkdir -p "$destination_dir"
	fi

	# download origin
	"$git_path" clone --mirror "$repo" "$destination_dir"

	# upstreamcount is used to generate names for the remotes
	upstreamcount=1	

	# set add remotes for each clone
	for clone in "${destinations[@]}"
	do
		# check if remote is not already added
		if ! "$git_path" -C "$destination_dir" remote show "mirror_${upstreamcount}" 2> /dev/null 1>&2
		then
			# add remote
			"$git_path" -C "$destination_dir" remote add "mirror_${upstreamcount}" "$clone"
		else
			# fetch from repo
			"$git_path" -C "$destination_dir" fetch origin
		fi

		# push to all remotes
		"$git_path" -C "$destination_dir" push --all "mirror_${upstreamcount}"

		# increase upstreamcount
		upstreamcount="$((upstreamcount + 1))"
	done
}

# mirror_repos mirrors all the repos.
function mirror_repos() {
	# run mirror_repo for all configs
	for repo in "${active[@]}"
	do
		repo_origin="${repo}_origin"

		# evaluate to get the array instead of the first value only
		# evaluates to "(${<reponam_clones>[@])"
		# copies the array to repo_clones
		eval repo_clones="(\${${repo}_clones[@]})"

		# mirror repo
		# pass repo_clones by name
		mirror_repo "$repo" "${!repo_origin}" "repo_clones"

	done
}

# load and check config
load_config
set_default
check_config

# create needed directories
create_mirror_root

# mirror repos
mirror_repos
