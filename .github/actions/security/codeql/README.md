<!-- markdownlint-disable MD013 -->

# CodeQL Security Scan GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A GitHub Action to **scan source code for security vulnerabilities using
CodeQL**.

This action automates **multi-language static analysis, SARIF report generation,
artifact upload, and optional GitHub Security (SARIF) integration** in CI/CD
workflows.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Automatic Language Detection](#automatic-language-detection)
  - [Compiled Languages](#compiled-languages)
  - [Disable GitHub Security Upload](#disable-github-security-upload)
- [Inputs](#inputs)
- [Outputs / Artifacts](#outputs--artifacts)
- [How it Works](#how-it-works)
- [CodeQL Query Suites](#codeql-query-suites)
- [SARIF and GitHub Security Integration](#sarif-and-github-security-integration)
- [References](#references)
- [License](#license)

---

## Features

- Scan **all supported languages automatically**
- Supports explicit language selection
- Supports **CodeQL query suite customization**
- Supports **automatic builds** for compiled languages
- Generates reports in **SARIF format**
- Uploads reports as **GitHub Actions artifacts**
- Optionally uploads SARIF results to
  **GitHub Security → Code scanning**
- Supports matrix builds via report suffixes
- No manual installation required

---

## Prerequisites

- GitHub repository with **GitHub Actions enabled**
- Repository checkout performed before invoking the action

Required permissions:

```yaml
permissions:
  contents: read
  actions: read
  security-events: write
```

For repositories containing compiled languages such as Java, C/C++,
C#, Go, Swift, or Rust, enabling `autobuild` is recommended.

CodeQL is automatically provisioned by this action —
no manual installation required.

---

## Usage

Create a workflow file such as `.github/workflows/codeql.yml`.

### Automatic Language Detection

Recommended for most repositories.

```yaml
name: CodeQL Security Scan

on:
  pull_request:

jobs:
  codeql:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      actions: read
      security-events: write

    steps:
      - uses: actions/checkout@v4

      - name: Run CodeQL
        uses: ./.github/actions/security/codeql
```

---

### Compiled Languages

```yaml
name: CodeQL Security Scan

on:
  push:
    branches:
      - main

jobs:
  codeql:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      actions: read
      security-events: write

    steps:
      - uses: actions/checkout@v4

      - name: Run CodeQL
        uses: ./.github/actions/security/codeql
        with:
          build-mode: autobuild
```

---

### Disable GitHub Security Upload

Reports are still generated and uploaded as workflow artifacts.

```yaml
- name: Run CodeQL
  uses: ./.github/actions/security/codeql
  with:
    upload-sarif: false
```

---

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `languages` | Languages to analyze (`auto` detects supported languages automatically) | ❌ | `auto` |
| `queries` | Query suite to execute | ❌ | `security-and-quality` |
| `build-mode` | Build mode (`none` or `autobuild`) | ❌ | `none` |
| `upload-sarif` | Upload SARIF to GitHub Security | ❌ | `true` |
| `report_suffix` | Suffix appended to artifact names | ❌ | `""` |
| `retention-days` | Artifact retention period | ❌ | `7` |
| `category` | Category associated with uploaded SARIF | ❌ | `/security/codeql` |

---

## Outputs / Artifacts

### Outputs

| Output | Description |
|--------|-------------|
| `report_path` | Path to the generated SARIF report |

### Uploaded Artifacts

Artifacts are uploaded automatically.

Examples:

- `codeql-results`
- `codeql-results-linux`
- `codeql-results-windows`

---

## How it Works

1. Initializes CodeQL databases
1. Detects supported languages automatically
1. Optionally performs an autobuild
1. Executes configured CodeQL queries
1. Generates SARIF reports
1. Uploads reports as GitHub Actions artifacts
1. Optionally publishes SARIF results to GitHub Security

---

## CodeQL Query Suites

The following built-in query suites are commonly used.

### `security-and-quality`

Default query suite.

Includes:

- Security vulnerability detection
- Reliability checks
- Maintainability analysis
- Code quality rules

### `security-extended`

Provides additional security-focused checks.

Example:

```yaml
- name: Run CodeQL
  uses: ./.github/actions/security/codeql
  with:
    queries: security-extended
```

---

## SARIF and GitHub Security Integration

When `upload-sarif` is enabled, findings appear under:

**GitHub → Security → Code scanning**

When disabled:

- SARIF reports are still generated
- SARIF reports are uploaded as workflow artifacts
- Results are not published to the Security tab

---

## References

- https://codeql.github.com/docs/
- https://docs.github.com/en/code-security/code-scanning
- https://github.com/github/codeql-action

---

## License

Apache License 2.0
