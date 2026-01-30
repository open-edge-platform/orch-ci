#!/usr/bin/env bash

# SPDX-FileCopyrightText: (C) 2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# halt script if an error occurs
set -eu -o pipefail

# Load the shared library
my_dir="$(dirname "$0")"
# shellcheck source=scripts/tagging-lib.sh
source "$my_dir/tagging-lib.sh"

# Note: expects the following variables to be set, as well as the existence of a netrc file
#       that contains github credentials.
#
echo "Passed Variables:"
echo "  GITHUB_USER=$GITHUB_USER"
echo "  REPO_NAME=$REPO_NAME"
echo "  REPO_OWNER=$REPO_OWNER"
echo "  REPO_BRANCH=$REPO_BRANCH"
echo "  PROJECT_NAME=$PROJECT_NAME"

RELEASE_PATH=$WORKSPACE/$BASEDIR

# cd to the code checkout location
cd "$RELEASE_PATH"

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

# If not a release version, then skip publish
if [ "$RELEASE_VERSION" -ne "1" ]; then
    exit
fi

# If validation failed, then abort
if [ "$FAIL_VALIDATION" -ne "0" ]; then
    exit
fi

# Helper
GITHUB_RELEASE=$(which github-release)

# glob pattern relative to project dir matching release artifacts
ARTIFACT_GLOB=${ARTIFACT_GLOB:-"release/*"}

# Temporary staging directory to copy artifacts to
RELEASE_TEMP="$WORKSPACE/release_staging"

# Create a release description from the git log
RELEASE_DESCRIPTION=$(git log -1 --pretty=%B | tr -dc "[:alnum:]\n\r\.\[\]\:\-\\\/\`\' ")

# Create the temporary staging directory, and copy release files to it
mkdir -p "$RELEASE_TEMP"

# build the release, can be multiple space separated targets
# shellcheck disable=SC2086
cp $ARTIFACT_GLOB "$RELEASE_TEMP"

# create release
$GITHUB_RELEASE release \
  --user "$REPO_OWNER" \
  --repo "$REPO_NAME" \
  --tag  "$TAG_VERSION" \
  --name "$PROJECT_NAME - $TAG_VERSION" \
  --description "$RELEASE_DESCRIPTION" \
  --target "$REPO_BRANCH"

# handle release files
pushd "$RELEASE_TEMP"
  # Generate and check checksums
  sha256sum -- * > checksum.SHA256
  sha256sum -c < checksum.SHA256
  echo "Checksums:"
  cat checksum.SHA256
  # upload all files to the release
  for rel_file in *
  do
    echo "Uploading file: $rel_file"
    #give github a break ¯\_(ツ)_/¯
    sleep 5
    $GITHUB_RELEASE upload \
      --user "$REPO_OWNER" \
      --repo "$REPO_NAME" \
      --tag  "$TAG_VERSION" \
      --name "$rel_file" \
      --file "$rel_file"
  done
popd

