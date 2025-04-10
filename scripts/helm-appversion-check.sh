#!/usr/bin/env bash

# SPDX-FileCopyrightText: (C) 2018-present Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

# helm-appversion-check.sh
# Version validation for Helm charts that apply appVersion from a VERSION file and
# chart version from each Helm Chart.yaml file.
# - Verifies that a "release" versioned chart ("#.#.#") will have a "release" appVersion ("#.#.#")
#   and with no "-dev" or other pre-release suffix as appVersion provides default container image
#   tag values and we don't want a "release" chart to inadvertently pull non-release images.

set -eu -o pipefail

# Load the shared library
my_dir="$(dirname "$0")"
# shellcheck source=scripts/tagging-lib.sh
source "$my_dir/tagging-lib.sh"

# Collect success/failure, and list/types of failures
fail_version=0
failed_charts=""

# when not running under github, use current dir as workspace
WORKSPACE=${WORKSPACE:-.}

read_version
echo "# helm-appversion-check.sh, VERSION == $NEW_VERSION #"

if [[ "$NEW_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
then
  echo "# helm-appversion-check.sh Success! - appVersion is release version - chart version check skipped #"
  exit 0
fi

echo "# helm-appversion-check.sh - appVersion is a non-release version - verifying non-release chart versions"

# For all the charts, fail if tagged with a release version when VERSION is a development version
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

  # Require version check for "-dev" versioned charts
  chart_version=$(yq .version "$chart")
  if [[ "$chart_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
  then
    echo "Error in $chart: Release version $chart_version referencing non-release appVersion $NEW_VERSION"
    fail_version=1
    failed_charts+=$'\n'
    failed_charts+="  $chart"
  else
    echo "Skipping non-release versioned chart: $chart - $chart_version"
    continue
  fi
done < <(find "${WORKSPACE}" -name Chart.yaml -print0)

if [[ $fail_version != 0 ]]; then
  echo "# helm-appversion-check.sh Failure! #"
  echo "Charts that need to be fixed:$failed_charts"
  exit 1
fi

echo "# helm-appversion-check.sh Success! - no release charts using non-released appVersion $NEW_VERSION #"
exit 0
