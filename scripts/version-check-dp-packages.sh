#!/usr/bin/env bash

# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -eu -o pipefail

echo "# Deployment Package Version Check #"

REGISTRY="registry-rs.edgeorchestration.intel.com"
REPO="edge-orch/en/file"

changed_files=$(git diff --name-only origin/main | grep 'deployment-package/.*/deployment-package.yaml' || true)

if [ -z "$changed_files" ]; then
  echo "✅ No deployment-package.yaml files changed. Skipping version check."
  exit 0
fi

for file in $changed_files; do
  name=$(yq '.name' "$file")
  version=$(yq '.version' "$file")

  echo "🔍 Checking: $name version $version"

  artifact="${REGISTRY}/${REPO}/${name}:${version}"
  echo "🔍 Checking registry for: $artifact"

  if oras pull "$artifact" --plain-http > /dev/null 2>&1; then
    echo "❌ Registry: Version $version of $name already exists in ORAS registry"
    exit 1
  else
    echo "✅ Registry: Version $version of $name not found"
  fi
done

echo "✅ All changed deployment package versions are new and safe to release."
exit 0