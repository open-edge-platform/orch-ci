#!/usr/bin/env bash

# Copyright 2018-2022 Open Networking Foundation
# Copyright 2023 Intel Corp.
# SPDX-License-Identifier: Apache-2.0

# version-tag.sh
# Tags a git commit with the SemVer version discovered within the commit,
# if the tag doesn't already exist. Ignore non-SemVer commits.

set -eux -o pipefail

# Load the shared library
my_dir="$(dirname "$0")"
# shellcheck source=scripts/tagging-lib.sh
source "$my_dir/tagging-lib.sh"

# create a git tag
function create_git_tag {
  echo "Creating git tag: $TAG_VERSION"
  local git_hash=""
  local commit_info=""

  git config --global user.email "do-not-reply@intel.com"
  git config --global user.name "github-bot"

  # Use token
  git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

  git_hash=$(git rev-parse --short HEAD)
  commit_info=$(git log --oneline | grep "${git_hash}")

  git tag -a "$TAG_VERSION" -m "Tagged by github-bot. COMMIT:${commit_info}"

  echo "Tags including new tag:"
  git tag -n

  git push origin "$TAG_VERSION"
}

# Start of actual code
echo "Checking git repo with remotes:"
git remote -v

echo "Branches:"
branches=$(git branch -v)
echo "$branches"

echo "Existing git tags:"
existing_tags=$(git tag -l)
echo "$existing_tags"

read_version
check_if_releaseversion

# perform checks if a released version
if [ "$RELEASE_VERSION" -eq "1" ]
then
  is_git_tag_duplicated
  dockerfile_parentcheck

  if [ "$FAIL_VALIDATION" -eq "0" ]
  then
    create_git_tag
  else
    echo "ERROR: commit merged but failed validation, not tagging!"
  fi
fi

exit "$FAIL_VALIDATION"
