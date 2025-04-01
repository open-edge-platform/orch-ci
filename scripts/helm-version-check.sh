#!/usr/bin/env bash

# SPDX-FileCopyrightText: (C) 2018-present Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

# helm-version-check.sh
# checks that changes to a chart include a change to the chart version

set -eu -o pipefail

# Load the shared library
my_dir="$(dirname "$0")"
# shellcheck source=scripts/tagging-lib.sh
source "$my_dir/tagging-lib.sh"

# when not running under Jenkins, use current dir as workspace
WORKSPACE=${WORKSPACE:-.}

# EXPLICIT_CURRENT_DIR defaults to 0.
# Set this to 1 if current directory (`.`) should be explicitly set for `git diff`.
# May be helpful for repositories containing multiple helm charts - without setting path explicitly
# git diff returns diff for the whole repository, not for the current directory in this repository,
# which may cause false positives.
EXPLICIT_CURRENT_DIR=${EXPLICIT_CURRENT_DIR:-0}

echo "# helm-version-check.sh, using git: $(git --version) #"

read_version
no_repo_version_file="$FAIL_VALIDATION"
echo "# helm-version-check.sh, version: $NEW_VERSION, version file: $VERSIONFILE, version missing: $no_repo_version_file #"

# Collect success/failure, and list/types of failures
add_versionfile_change=0
fail_version=0
failed_charts=""

# CHARTVERSION_IS_VERSION defaults to 0.
# Set this to 1 if Chart version is implicitely set by the repo build.
CHARTVERSION_IS_VERSION=${CHARTVERSION_IS_VERSION:-0}

# APPVERSION_IS_VERSION defaults to 1.
# Set this to 0 if Chart appVersion is not implicitely set by the repo build.
APPVERSION_IS_VERSION=${APPVERSION_IS_VERSION:-1}

# If there is no version file, it can't be used for chart version or appVersion
if [ $no_repo_version_file -ne 0 ]
then
  CHARTVERSION_IS_VERSION=0
  APPVERSION_IS_VERSION=0
fi

# branch to compare against, defaults to main
COMPARISON_BRANCH="${COMPARISON_BRANCH:-origin/main}"
echo "# Comparing with branch: $COMPARISON_BRANCH"

if [ "$EXPLICIT_CURRENT_DIR" -eq 1 ]
then
    # Create list of changed files compared to branch for the current directory (relative to current directory)
    changed_files=$(git diff --name-only --relative "${COMPARISON_BRANCH}")

    # Set WORKSPACE to current directory, so all paths comparisons are done correctly
    WORKSPACE=$(pwd)
else
    # Create list of changed files compared to branch for the whole repository
    changed_files=$(git diff --name-only "${COMPARISON_BRANCH}")
fi

# Create list of untracked by git files
untracked_files=$(git ls-files -o --exclude-standard)

# Print lists of files that are changed/untracked
if [ -z "$changed_files" ] && [ -z "$untracked_files" ]
then
  echo "# helm-version-check.sh - No changes, Success! #"
  exit 0
else
  if [ -n "$changed_files" ]
  then
    echo "Changed files compared with $COMPARISON_BRANCH:"
    # Search and replace per SC2001 doesn't recognize ^ (beginning of line)
    # shellcheck disable=SC2001
    echo "${changed_files}" | sed 's/^/  /'
  fi
  if [ -n "$untracked_files" ]
  then
    echo "Untracked files:"
    # shellcheck disable=SC2001
    echo "${untracked_files}" | sed 's/^/  /'
  fi
fi

# combine lists
if [ -n "$changed_files" ]
then
  if [ -n "$untracked_files" ]
  then
    changed_files+=$'\n'
    changed_files+="${untracked_files}"
  fi
else
  changed_files="${untracked_files}"
fi

# detect version file changed if either chart version or appVersion uses it
if [ "$CHARTVERSION_IS_VERSION" -eq 1 ] || [ "$APPVERSION_IS_VERSION" -eq 1 ] 
then
  [[ $changed_files =~ (^|[[:space:]])$VERSIONFILE($|[[:space:]]) ]] && add_versionfile_change=1
  echo "add_versionfile_change=$add_versionfile_change"
fi

# For all the charts, fail on changes within a chart without a version change
# loop on result of 'find -name Chart.yaml'
while IFS= read -r -d '' chart
do
  chartdir=$(dirname "${chart#"${WORKSPACE}"/}")

  # Is normalized chart path in the ignoreCharts list
  if [ -f ".chartver.yaml" ] && [ -n "$(yq '.ignoreCharts[] // "" ' .chartver.yaml)" ]
  then
    ignore_chart=0
    for ignore_path in $(yq '.ignoreCharts[] // "" ' .chartver.yaml)
    do
      if [[ "$chartdir/Chart.yaml" == "$ignore_path"* ]]
      then
        ignore_chart=1
        break
      fi
    done

    # Skip version check for "-dev" versioned charts
    if [[ "$ignore_chart" -eq 1 ]]
    then
      echo "Skipping ignored chart: $chart - ignored path: $ignore_path"
      continue
    fi
  fi

  chart_changed_files=""
  version_updated=0

  if [ "$CHARTVERSION_IS_VERSION" -eq 0 ]
  then
    # Use version from Chart.yaml by default
    chart_version=$(yq .version "$chart")
  else
    # Use NEW_VERSION since this repo overwrites the Chart.yaml version at build time
    chart_version="$NEW_VERSION"
  fi

  # Skip version check for "-dev" versioned charts
  if [[ "$chart_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\-dev.*$ ]]
  then
    echo "Skipping -dev versioned chart: $chart - $chart_version"
    continue
  fi

  # create a list of files that were changed in the chart
  if [ "$add_versionfile_change" -eq 1 ]
  then
    echo "add VERSIONFILE to changed chart files"
    chart_changed_files+=$'\n'
    chart_changed_files+="  ${VERSIONFILE}"
  fi
  for file in $changed_files; do
    if [[ $file =~ ^$chartdir/ ]]
    then
      chart_changed_files+=$'\n'
      chart_changed_files+="  ${file}"
    fi
  done

  if [ "$CHARTVERSION_IS_VERSION" -eq 0 ]
  then
    # See if chart version changed using 'git diff', and is SemVer
    chart_yaml_diff=$(git diff -p "$COMPARISON_BRANCH" -- "${chartdir}/Chart.yaml")

    if [ -n "$chart_yaml_diff" ]
    then
      echo "Changes to Chart.yaml in '$chartdir'"
      old_version_string=$(echo "$chart_yaml_diff" | awk '/^\-version:/ { print $2 }')
      new_version_string=$(echo "$chart_yaml_diff" | awk '/^\+version:/ { print $2 }')

      if [ -n "$new_version_string" ]
      then
        version_updated=1
        echo " Old version string:${old_version_string//-version:/}"
        echo " New version string:${new_version_string//+version:/}"
      fi
    fi
  else
    # Use VERSIONFILE for Chart version value
    if [ "$add_versionfile_change" -eq 1 ]
    then
      version_updated=1
      echo " New chart version:$NEW_VERSION"
    fi
  fi

  # if there are any changed files
  if [ -n "$chart_changed_files" ]
  then
    # and version updated, print changed files
    if [ $version_updated -eq 1 ]
    then
      echo " Files changed:${chart_changed_files}"
    else
      # otherwise fail this chart
      echo "Changes to chart but no version update in '$chartdir':${chart_changed_files}"
      fail_version=1
      failed_charts+=$'\n'
      failed_charts+="  $chartdir"
    fi
  fi

done < <(find "${WORKSPACE}" -name Chart.yaml -print0)

if [[ $fail_version != 0 ]]; then
  echo "# helm-version-check.sh Failure! #"
  echo "Charts that need to be fixed:$failed_charts"
  exit 1
fi

echo "# helm-version-check.sh Success! - all release charts have updated versions #"

exit 0

