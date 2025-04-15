# Open Edge Platform common CI Repository

Welcome to the `orch-ci` repository, the central hub for continuous integration
(CI) workflows and actions for the Open-Edge-Platform project. This repository
contains shared workflows, scripts, and actions designed to streamline and
automate the development and deployment processes across various
Open-Edge-Platform projects.

## Overview

The `orch-ci` repository provides a collection of reusable GitHub Actions and
workflows that can be integrated into other repositories within the
Open-Edge-Platform project. These workflows cover a range of CI tasks,
including building, testing, linting, security scanning, and version tagging.

## Repository Structure

### Root Directory

- **Documentation and Configuration**:
  - `CODE_OF_CONDUCT.md`: Guidelines for community behavior.
  - `CONTRIBUTING.md`: Instructions for contributing to the repository.
  - `LICENSES/Apache-2.0.txt`: License information for the repository.
  - `README.md`: Overview and instructions for the repository.
  - `SECURITY.md`: Security policies and procedures.
  - `VERSION`: Version information for the repository.

- **Scripts**:
  - `scripts/`: Contains various scripts for version checking, tagging, and
    other CI tasks.
    - `custom-version-tag.sh`: Custom script for tagging versions.
    - `github-release.sh`: Script for creating GitHub releases.
    - `helm-appversion-check.sh`: Checks Helm chart app versions.
    - `helm-version-check.sh`: Validates Helm chart versions.
    - `push_oci_packages.sh`: Pushes OCI packages.
    - `tagging-lib.sh`: Library for tagging operations.
    - `version-check.sh`: Checks version consistency.
    - `version-tag-param.sh`: Tags versions with parameters.
    - `version-tag.sh`: Tags versions based on commit information.

### .github Directory

- **Actions**:
  - `bootstrap/`: Sets up environments with necessary tools.
    - `action.yml`: Defines the bootstrap action.
  - `clamav/`: Runs ClamAV scans.
    - `action.yml`: Defines the ClamAV scan action.

- **Workflows**:
  - `apporch-go-fuzz.yml`: Workflow for Go fuzz testing.
  - `post-merge-edge-node-agents.yml`: Post-merge workflow for edge node agents.
  - `post-merge-orch-ci.yml`: Post-merge workflow for orch-ci.
  - `post-merge.yml`: General post-merge workflow.
  - `pre-merge-edge-node-agents.yml`: Pre-merge workflow for edge node agents.
  - `pre-merge-orch-ci.yml`: Pre-merge workflow for orch-ci.
  - `pre-merge.yml`: General pre-merge workflow.
  - `publish-documentation.yml`: Workflow for publishing documentation.
  - `test_bootstrap.yml`: Workflow for testing bootstrap actions.

## Key Workflows

### Post-Merge CI Pipeline

The `post-merge.yml` workflow is triggered after merging changes into the main
branch. It includes steps for building, testing, linting, security scanning,
and version tagging. It ensures that the codebase remains stable and secure
after changes are integrated.

### Pre-Merge CI Pipeline

The `pre-merge.yml` workflow runs before merging changes, providing a
comprehensive set of checks to validate the code. It includes license
compliance checks, secret scanning, and various build and test steps to ensure
code quality.

## Usage

To use the workflows and actions in this repository:

1. **Integrate Workflows**: Reference the shared workflows in your repository's
   `.github/workflows` directory using the `workflow_call` event.

2. **Use Actions**: Incorporate the actions defined in this repository into
   your workflows by specifying the path to the action in the `uses` field.

3. **Configure Inputs**: Customize the workflows by providing inputs as needed,
   such as enabling or disabling specific checks or scans.

## Developing

Before submitting changes, please run `make lint`, which will run a set of
linters on all of the files in the repository. This helps ensure code quality
and consistency across the project.

## Contributing

We welcome contributions to improve the CI processes. Please read the
`CONTRIBUTING.md` file for guidelines on how to contribute.

## License

This repository is licensed under the Apache License 2.0. See the
`LICENSES/Apache-2.0.txt` file for more details.

## Code of Conduct

Please adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) when interacting
with the community.

## Security

For security-related concerns, please refer to our [Security Policy](SECURITY.md).
