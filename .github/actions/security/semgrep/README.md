<!-- markdownlint-disable MD013 -->

# Semgrep SAST Scan GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Enterprise-grade GitHub Composite Action for running **Semgrep Static Application Security Testing (SAST)** with configurable scan scope, rule sets, severity filtering, SARIF reporting, artifact upload, and controlled failure behavior.

This action supports both incremental scanning (changed files only) and full repository scanning with structured output handling and GitHub Security integration.

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
- [Severity Handling Logic](#severity-handling-logic)
- [SARIF Integration](#sarif-integration)
- [Operational Considerations](#operational-considerations)
- [Security Governance Model](#security-governance-model)
- [References](#references)
- [License](#license)

---

## Overview

This composite action executes Semgrep to perform static code analysis across multiple programming languages.

Key capabilities include:

- Multi-language static analysis
- Configurable rule sets
- Incremental scanning
- Full repository scanning
- Severity threshold filtering
- SARIF output generation
- GitHub Code Scanning integration
- Controlled CI failure behavior
- Artifact retention management

Semgrep rules are configurable using predefined registry packs or custom rule definitions.

---

## Architecture and Execution Flow

The action executes in the following stages:

### 1. Scope Determination

- If `scan-scope` is `changed`, the action gathers changed files using `tj-actions/changed-files`.
- If `scan-scope` is `all`, it scans the defined `paths`.

### 2. Severity Mapping

The provided severity level is translated into Semgrep-compatible severity flags:

- LOW → INFO, WARNING, ERROR
- MEDIUM → WARNING, ERROR
- HIGH → ERROR
- CRITICAL → ERROR

### 3. Scan Execution

Semgrep runs with:

- Rule configuration from `config`
- Timeout enforcement
- Metrics disabled
- Output format control

### 4. Report Processing

If full scan mode is used:

- A report file is generated
- Stored under `security-results/semgrep`
- Uploaded as artifact
- Optionally uploaded to GitHub Security

### 5. Failure Evaluation

The job may fail based on:

- `fail-on-findings`
- Exit code returned by Semgrep

---

## Scan Modes

### Changed Files Mode

Activated when:

```yaml
scan-scope: changed
```

Behavior:

- Collects changed files from the workflow context.
- Executes Semgrep directly against those files.
- Outputs findings to workflow logs.
- Does not generate artifact file unless configured differently.
- Returns exit code for policy enforcement.

This mode is optimized for pull requests to reduce execution time and noise.

---

### Full Repository Mode

Activated when:

```yaml
scan-scope: all
```

Behavior:

- Scans all files under `paths`.
- Generates structured report file.
- Stores report in:

```text
security-results/semgrep/
```

- Sets `report_path` output.
- Uploads artifact.
- Optionally uploads SARIF to GitHub Security.

This mode is recommended for:

- Main branch protection
- Scheduled scans
- Compliance workflows

---

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| scan-scope | Scan scope (`changed` or `all`) | No | changed |
| paths | Target directory for full scan | No | . |
| config | Semgrep rule packs or config | No | Multiple registry packs |
| severity | Minimum severity threshold | No | LOW |
| timeout | Maximum runtime in seconds | No | 300 |
| output-format | text, json, or sarif | No | sarif |
| fail-on-findings | Fail workflow on findings | No | true |
| report_suffix | Optional artifact suffix | No | "" |
| upload-sarif | Upload SARIF to GitHub Security | No | true |

---

## Input-to-Behavior Mapping

| Input | Internal Effect |
|-------|----------------|
| scan-scope=changed | Uses changed-files action |
| scan-scope=all | Scans `paths` directory |
| severity | Maps to Semgrep severity flags |
| config | Sets `SEMGREP_RULES` environment variable |
| timeout | Applies `--timeout` flag |
| output-format | Controls CLI output type |
| fail-on-findings=true | Fails job if exit code ≠ 0 |
| upload-sarif=true | Triggers SARIF upload step |

---

## Outputs

| Output | Description |
|--------|------------|
| scan_result | Exit code returned by Semgrep |
| report_path | Path to generated report file |

---

## Report and Artifact Handling

For full scans:

- Report file name format:

```text
semgrep-results-<random>.sarif
```

- Stored under:

```text
security-results/semgrep
```

- Uploaded via `actions/upload-artifact`
- Retention period: 7 days

Artifacts allow traceability and audit retention independent of workflow logs.

---

## Failure Logic

Failure behavior depends on:

```yaml
fail-on-findings: true
```

If enabled:

- Any Semgrep findings matching severity threshold
- Producing non-zero exit code
- Causes workflow failure

If disabled:

- Findings are reported
- Workflow continues

This allows flexibility between:

- Enforcement mode
- Monitoring mode

---

## Usage Examples

### Pull Request Incremental Scan

```yaml
name: Semgrep PR Scan

on:
  pull_request:

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Semgrep (changed files)
        uses: ./.github/actions/security/semgrep
        with:
          scan-scope: changed
          severity: MEDIUM
```

---

### Full Repository Scan

```yaml
name: Semgrep Full Scan

on:
  push:
    branches:
      - main

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Semgrep (full repository)
        uses: ./.github/actions/security/semgrep
        with:
          scan-scope: all
          paths: src/
          output-format: sarif
          upload-sarif: true
```

---

## Severity Handling Logic

Semgrep requires explicit severity flags.

The action converts:

- LOW → INFO + WARNING + ERROR
- MEDIUM → WARNING + ERROR
- HIGH → ERROR
- CRITICAL → ERROR

This ensures deterministic filtering aligned with enterprise risk models.

---

## SARIF Integration

When:

```yaml
upload-sarif: true
output-format: sarif
```

The SARIF file is uploaded using:

- `github/codeql-action/upload-sarif`

Results appear in:

GitHub → Security → Code scanning

Ensure workflow permissions include:

```yaml
permissions:
  security-events: write
```

---

## Operational Considerations

- Use incremental mode for PRs to reduce runtime.
- Use full scans on protected branches.
- Combine with scheduled workflows for compliance scanning.
- Monitor artifact retention policies.
- Maintain rule packs aligned with organizational policy.

---

## Security Governance Model

This action supports enterprise security programs by enabling:

- Shift-left security
- Policy-driven enforcement
- Auditable reporting
- CI-integrated vulnerability detection
- Structured artifact retention
- GitHub-native vulnerability tracking

It is suitable for:

- Regulated environments
- Secure SDLC pipelines
- DevSecOps programs
- Multi-language repositories

---

## References

- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Semgrep Registry](https://semgrep.dev/explore)
- [GitHub Code Scanning Documentation](https://docs.github.com/en/code-security/code-scanning)

---

## License

Apache License 2.0
