#!/usr/bin/env bash

# Copyright 2018-2022 Open Networking Foundation
# Copyright 2024 Intel Corp.
# SPDX-License-Identifier: Apache-2.0

# version-tag-param.sh
# Tags a git commit with the SemVer version discovered within the commit,
# if the tag doesn't already exist. Ignore non-SemVer commits.
# Uses a param, if specified as input to the script, to set a prefix in the tag.

set -eu -o pipefail

# Load the shared library
my_dir="$(dirname "$0")"
# shellcheck source=scripts/tagging-lib.sh
source "$my_dir/tagging-lib.sh"

#remove any entries from the auth header
git config --global --unset http.https://github.com/.extraheader || true
# Use token
git config http.https://github.com/.extraheader "AUTHORIZATION: basic $(echo -n x-access-token:"$GITHUB_TOKEN" | base64)"

TAG_PARAM=$1

# create a git tag
function create_git_tag {
  echo "Creating git tag: $TAG_VERSION"
  local git_hash=""
  local commit_info=""

  git config --global user.email "do-not-reply@intel.com"
  git config --global user.name "github-bot@intel.com "

  git_hash=$(git rev-parse --short HEAD)
  commit_info=$(git log --oneline | grep "${git_hash}")

  git tag -a "$TAG_VERSION" -m "Tagged by github-bot. COMMIT:${commit_info}"

  echo "Tags including new tag:"
  git tag -n

  git push origin "$TAG_VERSION"
  create_release
  upload_asset_to_release "$ASSET_PATH" "$ASSET_NAME"
}

# create a release using GitHub CLI
function create_release {
  echo "Creating release for tag: $TAG_VERSION"
  gh release create "$TAG_VERSION" --title "Release $TAG_VERSION" --notes "Release notes for $TAG_VERSION"
}

# upload asset to GitHub release using GitHub CLI
function upload_asset_to_release {
  local asset_path="standalone-node/requirements.txt"
  local asset_name="requirements.txt"

  echo "Uploading asset to release: $TAG_VERSION"
  gh release upload "$TAG_VERSION" "$asset_path" --clobber --name "$asset_name"
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

RETURN_CODE=0
# perform checks if a released version
if [ "$RELEASE_VERSION" -eq "1" ]
then
  # Assigns TAG_VERSION with a prefix provided by script $1 parameter (if present)
  TAG_VERSION="${TAG_PARAM}${TAG_VERSION}"
  echo "${TAG_VERSION}"
  is_git_tag_duplicated
  dockerfile_parentcheck

  if [ "$FAIL_VALIDATION" -eq "2" ]
  then
    echo "WARN: $TAG_VERSION is already present, not tagging!"
    RETURN_CODE=0 # do not error out if tag already exists
  elif [ "$FAIL_VALIDATION" -eq "0" ]
  then
    create_git_tag
    RETURN_CODE=$FAIL_VALIDATION
    #if [ "$TAG_PARAM" == "standalone-node/" ]; then
     # upload_asset_to_release "standalone-node/requirements.txt" "requirements.txt"
    #else
     # echo "Project name is not standalone-node, skipping asset upload."
    #fi
  else
    echo "ERROR: commit merged but failed validation, not tagging!"
    RETURN_CODE=$FAIL_VALIDATION
  fi
fi

#remove any entries from the auth header
git config --global --unset http.https://github.com/.extraheader || true

exit "$RETURN_CODE"
