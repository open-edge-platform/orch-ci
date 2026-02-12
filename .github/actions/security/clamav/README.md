<!-- markdownlint-disable MD013 -->

# ClamAV Security Scan GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A GitHub Action to **scan repositories for malware using ClamAV**.  
This action automates **antivirus scanning, virus database updates, structured report generation, artifact upload, and optional pipeline enforcement** within CI/CD workflows.

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
- [Input-to-Behavior Mapping](#input-to-behavior-mapping)
- [Failure Logic](#failure-logic)
- [Report Generation](#report-generation)
- [Security Model](#security-model)
- [References](#references)
- [License](#license)

---

## Features

- Malware and infected file detection
- Incremental scanning using changed files
- Full recursive repository scanning
- Automatic virus definition updates
- Configurable file size limits
- Directory exclusion support
- JSON and TXT reporting formats
- GitHub Actions artifact upload
- Optional enforcement mode
- Containerized deterministic execution

---

## Prerequisites

- GitHub repository with Actions enabled
- Ubuntu-based runner
- Sufficient disk space for virus definitions

No manual installation is required.  
The action runs using the official ClamAV container image.

---

## Usage

Create `.github/workflows/clamav.yml`.

### Scan Changed Files

Recommended for pull requests.

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

