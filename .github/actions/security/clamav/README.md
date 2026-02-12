```{=html}
<!-- markdownlint-disable MD013 -->
```
# ClamAV Security Scan GitHub Action

[![License: Apache
2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A GitHub Action to **scan repositories for malware using ClamAV**.\
This action automates **antivirus scanning, virus database updates,
structured report generation, artifact upload, and optional pipeline
enforcement** within CI/CD workflows.

------------------------------------------------------------------------

## Table of Contents

-   [Features](#features)
-   [Prerequisites](#prerequisites)
-   [Usage](#usage)
    -   [Scan Changed Files](#scan-changed-files)
    -   [Scan Entire Repository](#scan-entire-repository)
-   [Inputs](#inputs)
-   [Outputs and Artifacts](#outputs-and-artifacts)
-   [How it Works](#how-it-works)
-   [Scan Scope Behavior](#scan-scope-behavior)
-   [Input-to-Behavior Mapping](#input-to-behavior-mapping)
-   [Failure Logic](#failure-logic)
-   [Report Generation](#report-generation)
-   [Security Model](#security-model)
-   [References](#references)
-   [License](#license)

------------------------------------------------------------------------

## Features

-   Malware and infected file detection
-   Incremental scanning using changed files
-   Full recursive repository scanning
-   Automatic virus definition updates
-   Configurable file size limits
-   Directory exclusion support
-   JSON and TXT reporting formats
-   GitHub Actions artifact upload
-   Optional enforcement mode
-   Containerized deterministic execution

------------------------------------------------------------------------

## Prerequisites

-   GitHub repository with Actions enabled
-   Ubuntu-based runner
-   Sufficient disk space for virus definitions

No manual installation is required.\
The action runs using the official ClamAV container image.

------------------------------------------------------------------------

## Usage

Create `.github/workflows/clamav.yml`.

### Scan Changed Files

Recommended for pull requests.

``` yaml
name: ClamAV Security Scan

on:
  pull_request:

jobs:
  clamav:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run ClamAV (changed files)
        uses: ./.github/actions/security/clamav
        with:
          scan-scope: changed
          exclude_dirs: ".git,node_modules"
```

------------------------------------------------------------------------

### Scan Entire Repository

Recommended for scheduled or main branch scans.

``` yaml
name: ClamAV Full Scan

on:
  push:
    branches:
      - main
  schedule:
    - cron: "0 3 * * *"

jobs:
  clamav:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run ClamAV (full repo)
        uses: ./.github/actions/security/clamav
        with:
          scan-scope: full
          exclude_dirs: ".git,node_modules"
```

------------------------------------------------------------------------

## Inputs

  --------------------------------------------------------------------------------------
  Name                  Description             Required           Default
  --------------------- ----------------------- ------------------ ---------------------
  `scan-scope`          Scan mode: `changed` or Yes                `changed`
                        `full`                                     

  `exclude_dirs`        Comma-separated         No                 `.git,node_modules`
                        directories to exclude                     

  `max_file_size`       Maximum file size to    No                 `25M`
                        scan (e.g. `25M`)                          

  `fail_on_detection`   Fail workflow if        No                 `true`
                        malware detected                           

  `report_format`       Report format: `json`,  No                 `both`
                        `txt`, or `both`                           
  --------------------------------------------------------------------------------------

------------------------------------------------------------------------

## Outputs and Artifacts

The action generates:

-   `clamav-report.txt`
-   `clamav-report.json` (if enabled)

These are uploaded automatically as GitHub Actions artifacts.

Artifacts include:

-   Scan summary
-   Detected threats (if any)
-   Scanned file count
-   Excluded directories
-   Virus definition version

------------------------------------------------------------------------

## How it Works

1.  Pulls the official ClamAV container image.
2.  Updates virus definitions using `freshclam`.
3.  Determines scan scope:
    -   Changed files (via git diff)
    -   Entire repository
4.  Applies exclusions and file size limits.
5.  Runs `clamscan` with appropriate flags.
6.  Generates structured reports.
7.  Uploads reports as workflow artifacts.
8.  Optionally fails the pipeline if threats are detected.

------------------------------------------------------------------------

## Scan Scope Behavior

### `changed`

-   Scans only files modified in the pull request.
-   Faster execution.
-   Ideal for CI validation.

### `full`

-   Recursively scans entire repository.
-   Recommended for scheduled security audits.

------------------------------------------------------------------------

## Input-to-Behavior Mapping

  Input                 Affects
  --------------------- -----------------------------
  `scan-scope`          Determines target file set
  `exclude_dirs`        Adds `--exclude-dir` flags
  `max_file_size`       Adds `--max-filesize` flag
  `fail_on_detection`   Controls exit code behavior
  `report_format`       Controls report generation

------------------------------------------------------------------------

## Failure Logic

If `fail_on_detection` is set to `true`:

-   Workflow fails when infected files are detected.
-   Exit code from ClamAV propagates to GitHub Actions.

If set to `false`:

-   Workflow completes successfully.
-   Reports still generated.
-   Threats visible in artifacts.

------------------------------------------------------------------------

## Report Generation

### TXT Report

Human-readable format including:

-   Scan summary
-   File counts
-   Infection details

### JSON Report

Structured format including:

-   Metadata
-   Timestamp
-   Scan scope
-   Detection results
-   File-level details

Useful for:

-   Security dashboards
-   SIEM ingestion
-   Automated compliance tracking

------------------------------------------------------------------------

## Security Model

-   Runs in isolated container
-   No host-level dependency installation
-   Uses official ClamAV image
-   No external network access beyond virus database updates
-   Artifacts stored securely in GitHub

Designed for CI/CD supply chain protection.

------------------------------------------------------------------------

## References

-   ClamAV Documentation\
    https://docs.clamav.net/

-   GitHub Actions Documentation\
    https://docs.github.com/actions

------------------------------------------------------------------------

## License

Licensed under the Apache License, Version 2.0.\
See the LICENSE file for details.
