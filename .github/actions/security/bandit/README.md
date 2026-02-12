<!-- markdownlint-disable MD013 -->

# Bandit Security Scan GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A GitHub Action to **scan Python code for security vulnerabilities using
[Bandit](https://bandit.readthedocs.io/en/latest/)**.  
This action automates **static security analysis, report generation, artifact
upload, and GitHub Security (SARIF) integration** in CI/CD workflows.

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
- [Bandit Configuration](#bandit-configuration)
- [SARIF and GitHub Security Integration](#sarif-and-github-security-integration)
- [References](#references)
- [License](#license)

---

## Features

- Scan **Python source code** for common security issues
- Supports **incremental scanning** (changed files only)
- Supports **full repository scans**
- Configurable **severity** and **confidence** thresholds
- Generates reports in multiple formats:
  - `sarif` (default)
  - `json`, `txt`, `html`, `csv`
- Uploads reports as **GitHub Actions artifacts**
- Uploads SARIF results to **GitHub Security → Code scanning**
- Optional **pipeline failure** when issues are detected
- Supports Bandit configuration via `pyproject.toml`

---

## Prerequisites

- GitHub repository with **GitHub Actions enabled**
- Python code (`.py`, `.pyx`, `.pyi`) in the repository
- GitHub token with permissions for SARIF upload (optional)

```yaml
permissions:
  security-events: write
```

Bandit is automatically installed by this action — no manual installation required.

---

## Usage

Create a workflow file such as `.github/workflows/bandit.yml`.

### Scan Changed Files

Recommended for **pull requests**.

```yaml
name: Bandit Security Scan

on:
  pull_request:

jobs:
  bandit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Bandit (changed files)
        uses: ./.github/actions/security/bandit
        with:
          scan-scope: changed
          severity-level: MEDIUM
```

---

### Scan Entire Repository

```yaml
name: Bandit Full Scan

on:
  push:
    branches:
      - main

jobs:
  bandit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Bandit (full scan)
        uses: ./.github/actions/security/bandit
        with:
          scan-scope: all
          paths: src/
          output-format: sarif
          upload-sarif: true
```

---

## Inputs

| Input | Description | Required | Default |
|------|------------|----------|---------|
| `scan-scope` | Scan scope: `changed` or `all` | ❌ | `changed` |
| `paths` | Paths to scan when using `all` scope | ❌ | `.` |
| `config_file` | Path to `pyproject.toml` or Bandit config | ❌ | `pyproject.toml` |
| `severity-level` | Minimum severity | ❌ | `LOW` |
| `confidence-level` | Minimum confidence | ❌ | `LOW` |
| `output-format` | Report format | ❌ | `sarif` |
| `fail-on-findings` | Fail job if issues are found | ❌ | `true` |
| `upload-sarif` | Upload SARIF to GitHub Security | ❌ | `true` |

---

## Outputs / Artifacts

Artifacts are uploaded with a unique suffix.

- `bandit-report-*.sarif`
- `bandit-report-*.json`
- `bandit-report-*.html`
- `bandit-report-*.csv`

---

## How it Works

1. Installs Python and Bandit
2. Determines scan scope
3. Runs Bandit with configured filters
4. Uploads reports
5. Publishes SARIF results to GitHub Security

---

## Bandit Configuration

```toml
[tool.bandit]
exclude_dirs = ["tests", "docs"]
skips = ["B101"]
severity = "LOW"
confidence = "LOW"
```

---

## SARIF and GitHub Security Integration

Results appear under **GitHub → Security → Code scanning**.

---

## References

- [Bandit Documentation](https://bandit.readthedocs.io/)
- [Bandit GitHub Repository](https://github.com/PyCQA/bandit)

---

## License

Apache License 2.0
