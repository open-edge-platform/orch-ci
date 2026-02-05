#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2018-2022 Open Networking Foundation
# SPDX-FileCopyrightText: 2022 Intel Corp.
# SPDX-License-Identifier: Apache-2.0

# version-check.sh
# validates if a version provided in VERSION file is valid

set -eu -o pipefail

# Load the shared library
my_dir="$(dirname "$0")"
# shellcheck source=scripts/tagging-lib.sh
source "$my_dir/tagging-lib.sh"

# cd to the code checkout location
cd "$WORKSPACE/$BASEDIR"

TAG_PREFIX=${1:-""}

echo "TAG_PREFIX is: ${TAG_PREFIX}"

# --- compute alternate prefix for compatibility ---
if [[ "$TAG_PREFIX" == */ ]]; then
  ALT_TAG_PREFIX="${TAG_PREFIX}v"
else
  ALT_TAG_PREFIX="${TAG_PREFIX%/}/"
fi
echo "Alternate TAG_PREFIX is: ${ALT_TAG_PREFIX}"

# helper function to check if a tag exists with either prefix
tag_exists() {
  local version="$1"
  grep -qx "${TAG_PREFIX}${version}" <<< "$existing_tags" || \
  grep -qx "${ALT_TAG_PREFIX}${version}" <<< "$existing_tags"
}

# --------------------------------------------------
# Prevent bumping from X.Y.Z → X.Y.Z-dev
# --------------------------------------------------
function reject_backward_dev_bump {

  [[ "$NEW_VERSION" =~ -dev$ ]] || return 0

  base_version="${NEW_VERSION%-dev}"
  if tag_exists "$base_version"; then
    echo "ERROR: Cannot bump from release $base_version to $NEW_VERSION"
    IFS='.' read -r MAJOR MINOR PATCH <<< "$base_version"
    echo "Suggested next dev version: ${TAG_PREFIX}${MAJOR}.${MINOR}.$((PATCH + 1))-dev"
    FAIL_VALIDATION=1
    exit 1
  fi
}

# --------------------------------------------------
# Check if a previous tag has been created
# --------------------------------------------------
function is_valid_version {

  if [[ "$CALENDAR_VERSION" == "true" ]]; then
    return
  fi

  local MAJOR=0 MINOR=0 PATCH=0
  local C_MAJOR=0 C_MINOR=0 C_PATCH=0

  semverParse "$NEW_VERSION" MAJOR MINOR PATCH

  found_parent=false
  parent_version=""

  check_parent_tag() {
    local version_to_check="$1"

    for existing_tag in $existing_tags; do
      if [[ $existing_tag == "${TAG_PREFIX}"* ]] || [[ $existing_tag == "${ALT_TAG_PREFIX}"* ]]; then
        semverParse "$existing_tag" C_MAJOR C_MINOR C_PATCH

        case "$version_to_check" in
          *.x.x)
            [[ "$C_MAJOR" == "${version_to_check%%.*}" ]] && found_parent=true && return
            ;;
          *.*.x)
            IFS='.' read -r VMAJ VMIN _ <<< "$version_to_check"
            [[ "$C_MAJOR" == "$VMAJ" && "$C_MINOR" == "$VMIN" ]] && found_parent=true && return
            ;;
          *)
            [[ "$C_MAJOR.$C_MINOR.$C_PATCH" == "$version_to_check" ]] && found_parent=true && return
            ;;
        esac
      fi
    done
  }

  # if patch == 0, check that there was a release with MAJOR.MINOR-1.X
  if [[ "$PATCH" == 0 && "$MINOR" -gt 0 ]]; then
    prev_minor=$(( MINOR - 1 ))
    parent_version="$MAJOR.$prev_minor.x"
    echo "Patch is 0, checking for parent version $parent_version"
    check_parent_tag "$parent_version"
  fi

  # if patch != 0 check that there was a release with MAJOR.MINOR.PATCH-1
  if [[ "$PATCH" != 0 ]]; then
    prev_patch=$(( PATCH - 1 ))
    parent_version="$MAJOR.$MINOR.$prev_patch"
    echo "Patch is not 0, checking for parent version $parent_version"
    check_parent_tag "$parent_version"
  fi

  # At the beginning there can be no parent, which is OK
  if [[ "$MAJOR" == 0 ]]; then
    echo "Major version is 0, prerelease, so OK"
    found_parent=true
  fi

  # May be tagging the first 1.0.0 release with no prior tags
  if [[ "$MAJOR" == 1 && "$MINOR" == 0 && "$PATCH" == 0 ]]; then
    echo "First 1.0.0 release, so OK"
    found_parent=true
  fi
  
  # New major version line with no applicable parent checks → OK
  if [[ "$MINOR" == 0 && "$PATCH" == 0 && "$MAJOR" -gt 1 ]]; then
    echo "New major version $MAJOR.x.x, no parent required"
    found_parent=true
  fi

  if [[ $found_parent == false ]]; then
    echo "Invalid $NEW_VERSION version. Expected parent version matching $parent_version does not exist."
    FAIL_VALIDATION=1
  fi
}

# --------------------------------------------------
# Start of actual code
# --------------------------------------------------
echo "Checking git repo with remotes:"
git remote -v

echo "Branches:"
branches=$(git branch -v)
echo "$branches"

echo "Existing git tags:"
existing_tags=$(git tag -l)
echo "$existing_tags"

read_version
reject_backward_dev_bump
is_valid_version
check_if_releaseversion

# perform checks if a released version
if [ "$RELEASE_VERSION" -eq "1" ]; then
  is_git_tag_duplicated "$existing_tags"
  dockerfile_parentcheck
fi

exit "$FAIL_VALIDATION"
