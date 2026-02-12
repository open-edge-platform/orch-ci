<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD030 -->
<!-- markdownlint-disable MD034 -->

# Gitleaks Secret Scanner GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Enterprise-grade GitHub Composite Action for detecting hardcoded secrets and credentials using **Gitleaks**.  
This action supports incremental scanning, full repository scanning, SARIF integration, artifact management, baseline handling, and configurable failure policies.

Designed for secure CI/CD pipelines and DevSecOps environments.

---

## Table of Contents

- [Overview](#overview)
- [Architecture and Execution Flow](#architecture-and-execution-flow)
- [Scan Modes](#scan-modes)
  - [Changed Files Mode](#changed-files-mode)
  - [Full Repository Mode](#full-repository-mode)
- [Inputs](#inputs)
- [Input-to-Behavior Mapping](#input-to-behavior-mapping)
- [Outputs](#outputs)
- [Report and Artifact Handling](#report-and-artifact-handling)
- [Failure Logic](#failure-logic)
- [Usage Examples](#usage-examples)
  - [Pull Request Incremental Scan](#pull-request-incremental-scan)
  - [Full Repository Scan](#full-repository-scan)
- [Baseline and Configuration Handling](#baseline-and-configuration-handling)
- [SARIF Integration](#sarif-integration)
- [Operational Considerations](#operational-considerations)
- [Security Governance Model](#security-governance-model)
- [References](#references)
- [License](#license)

---

## Overview

This composite action runs **Gitleaks** to detect exposed secrets such as:

- API keys
- Cloud credentials
- Tokens
- Passwords
- Private keys
- Hardcoded secrets in source files

### Key Capabilities

- Incremental scanning (changed files only)
- Full repository scanning
- Custom configuration support
- Baseline suppression support
- Redaction of sensitive findings
- SARIF output for GitHub Security
- Artifact upload
- Configurable exit code behavior

---

## Architecture and Execution Flow

### 1. Scope Resolution

Based on `scan-scope`:

- `changed` → Collect changed files using `tj-actions/changed-files`
- `all` → Scan entire directory specified by `source`

### 2. Environment Setup

- Resolves Gitleaks version (`latest` or pinned)
- Downloads official release
- Installs binary in runner environment

### 3. Scan Execution

Builds CLI dynamically based on:

- Source directory
- Report format
- Redaction setting
- Baseline configuration
- Custom config file
- Exit code policy

### 4. Report Processing

- Generates report file
- Writes report path to output
- Uploads artifact
- Optionally uploads SARIF

### 5. Exit Code Evaluation

Exit code is captured and surfaced to workflow caller.

---

## Scan Modes

### Changed Files Mode

Activated when:

```yaml
scan-scope: changed
```

Behavior:

- Detects modified files in the workflow context
- Reconstructs temporary directory containing changed files
- Executes Gitleaks with `--no-git`
- Reduces scan time
- Generates report file
- Returns exit code

---

### Full Repository Mode

Activated when:

```yaml
scan-scope: all
```

Behavior:

- Scans entire repository or specified `source`
- Uses Git history (if available)
- Generates structured report
- Saves output to:

```text
security-results/gitleaks/
```

- Sets `report_path`
- Uploads artifact
- Optionally uploads SARIF

---

## Inputs

| Input | Description | Required | Default |
|-------|------------|----------|---------|
| scan-scope | Scan scope (`changed` or `all`) | No | changed |
| source | Directory to scan | No | . |
| version | Gitleaks version or `latest` | No | latest |
| config_path | Custom Gitleaks config file | No | "" |
| baseline_path | Baseline file for known leaks | No | "" |
| report_format | `sarif`, `json`, or `csv` | No | sarif |
| redact | Redact secrets in output | No | true |
| exit_code_on_leak | Exit code if leaks found | No | 1 |
| report_suffix | Optional artifact suffix | No | "" |
| upload-sarif | Upload SARIF to GitHub Security | No | true |

---

## Input-to-Behavior Mapping

| Input | Internal Behavior |
|-------|------------------|
| scan-scope=changed | Uses temporary directory with changed files |
| scan-scope=all | Scans full `source` path |
| version | Downloads specific Gitleaks binary |
| config_path | Adds `--config` flag |
| baseline_path | Adds `--baseline-path` flag |
| report_format | Controls output file type |
| redact=true | Adds `--redact` flag |
| exit_code_on_leak | Sets CLI `--exit-code` |
| upload-sarif=true | Triggers SARIF upload step |

---

## Outputs

| Output | Description |
|--------|------------|
| exit_code | Exit code returned by Gitleaks |
| report_path | Path to generated report file |

---

## Report and Artifact Handling

Reports stored in:

```text
security-results/gitleaks
```

File naming pattern:

```text
gitleaks-results-<random>.<format>
```

Uploaded via `actions/upload-artifact`  
Retention period: 7 days

---

## Failure Logic

Controlled via:

```yaml
exit_code_on_leak
```

If set to `1` (default):

- Leaks cause non-zero exit code
- Workflow may fail depending on calling job

If set to `0`:

- Leaks reported
- Workflow continues

---

## Usage Examples

### Pull Request Incremental Scan

```yaml
name: Gitleaks PR Scan

on:
  pull_request:

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Gitleaks (changed files)
        uses: ./.github/actions/security/gitleaks
        with:
          scan-scope: changed
          report_format: sarif
```

---

### Full Repository Scan

```yaml
name: Gitleaks Full Scan

on:
  push:
    branches:
      - main

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Gitleaks (full repository)
        uses: ./.github/actions/security/gitleaks
        with:
          scan-scope: all
          source: .
          report_format: sarif
          upload-sarif: true
```

---

## Baseline and Configuration Handling

### Custom Configuration

```yaml
config_path: ./ci/gitleaks.toml
```

### Baseline Support

```yaml
baseline_path: ./ci/gitleaks-baseline.json
```

---

## SARIF Integration

```yaml
report_format: sarif
upload-sarif: true
```

Uses:

- `github/codeql-action/upload-sarif`

Ensure workflow permissions include:

```yaml
permissions:
  security-events: write
```

---

## Operational Considerations

- Use incremental mode for pull requests
- Use full scan on protected branches
- Maintain updated Gitleaks version
- Refresh baseline files regularly
- Monitor artifact retention policies

---

## Security Governance Model

Enables:

- Secret detection in CI
- Shift-left security enforcement
- Auditable reporting
- Baseline-managed remediation
- GitHub-native vulnerability tracking

---

## References

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)

---

## License

Apache License 2.0

