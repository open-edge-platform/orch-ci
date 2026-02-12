<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD030 -->
<!-- markdownlint-disable MD034 -->

# ClamAV Security Scan GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A GitHub Action to **scan repositories for malware using
[ClamAV](https://www.clamav.net/)**.  
This action automates **antivirus scanning, virus definition updates,
report generation, artifact upload, and optional pipeline enforcement**
in CI/CD workflows.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Scan Changed Files](#scan-changed-files)
  - [Scan Entire Repository](#scan-entire-repository)
- [Inputs](#inputs)
- [Outputs / Artifacts](#outputs--artifacts)
- [How it Works](#how-it-works)
- [Scan Scope Behavior](#scan-scope-behavior)
- [Failure Logic](#failure-logic)
- [Report Generation](#report-generation)
- [Security Model](#security-model)
- [References](#references)
- [License](#license)

---

## Features

- Scan repositories for **malware and infected files**
- Supports **incremental scanning** (changed files only)
- Supports **full repository scans**
- Automatically updates **virus definitions**
- Configurable **file size limits**
- Directory exclusion support
- Generates reports in multiple formats:
  - `json`
  - `txt`
  - `both`
- Uploads reports as **GitHub Actions artifacts**
- Optional **pipeline failure** when threats are detected
- Runs in a **containerized, deterministic environment**

---

## Prerequisites

- GitHub repository with **GitHub Actions enabled**
- Ubuntu-based runner (`ubuntu-latest`)
- Sufficient disk space for virus definition updates

No manual installation is required.  
ClamAV runs using the official container image.

---

## Usage

Create a workflow file such as `.github/workflows/clamav.yml`.

### Scan Changed Files

Recommended for **pull requests**.

```yaml
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

---

### Scan Entire Repository

```yaml
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

      - name: Run ClamAV (full scan)
        uses: ./.github/actions/security/clamav
        with:
          scan-scope: full
          exclude_dirs: ".git,node_modules"
```

---

## Inputs

| Input | Description | Required | Default |
|-------|------------|----------|---------|
| `scan-scope` | Scan scope: `changed` or `full` | No | `changed` |
| `exclude_dirs` | Directories to exclude (comma-separated) | No | `.git,node_modules` |
| `max_file_size` | Maximum file size to scan (e.g. `25M`) | No | `25M` |
| `fail_on_detection` | Fail job if malware is detected | No | `true` |
| `report_format` | Report format: `json`, `txt`, or `both` | No | `both` |

---

## Outputs / Artifacts

Artifacts are uploaded automatically.

- `clamav-report.txt`
- `clamav-report.json` (if enabled)

Artifacts include:

- Scan summary
- Detected threats (if any)
- Total scanned file count
- Excluded directories
- Virus definition version

---

## How it Works

1. Pulls the official ClamAV container image.
1. Updates virus definitions using `freshclam`.
1. Determines scan scope:
   - Changed files (via `git diff`)
   - Entire repository
1. Applies configured exclusions and file size limits.
1. Executes `clamscan`.
1. Generates reports.
1. Uploads reports as workflow artifacts.
1. Optionally fails the pipeline if threats are detected.

---

## Scan Scope Behavior

### `changed`

- Scans only files modified in the pull request.
- Faster execution.
- Ideal for CI validation.

### `full`

- Recursively scans the entire repository.
- Recommended for scheduled security audits.

---

## Failure Logic

If `fail_on_detection` is set to `true`:

- Workflow fails when infected files are detected.
- ClamAV exit code propagates to GitHub Actions.

If set to `false`:

- Workflow completes successfully.
- Reports are still generated.
- Threats remain visible in artifacts.

---

## Report Generation

### TXT Report

Human-readable report including:

- Scan summary
- File counts
- Infection details

### JSON Report

Structured report including:

- Metadata
- Timestamp
- Scan scope
- Detection results
- File-level details

Useful for:

- Security dashboards
- SIEM ingestion
- Compliance tracking
- Automated reporting systems

---

## Security Model

- Runs inside an isolated container.
- No host-level dependency installation.
- Uses official ClamAV image.
- No external network access beyond virus database updates.
- Artifacts stored securely within GitHub.

Designed for CI/CD supply chain protection.

---

## References

- https://docs.clamav.net/
- https://www.clamav.net/
- https://docs.github.com/actions

---

## License

Apache License 2.0
