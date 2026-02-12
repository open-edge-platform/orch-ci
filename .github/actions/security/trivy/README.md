<!-- markdownlint-disable MD013 -->

# Trivy Security Scanner GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Enterprise-grade GitHub Composite Action for performing comprehensive security scanning using **Trivy**.  
This action supports vulnerability scanning, misconfiguration analysis, secret detection, compliance benchmarking, and SBOM generation across multiple scan targets.

Designed for secure CI/CD pipelines and DevSecOps environments.

---

## Table of Contents

- [Overview](#overview)
- [Architecture and Execution Flow](#architecture-and-execution-flow)
- [Scan Scope Behavior](#scan-scope-behavior)
  - [Changed Files Mode](#changed-files-mode)
  - [Full Scope Mode](#full-scope-mode)
- [Scan Types](#scan-types)
- [Inputs](#inputs)
- [Input-to-Behavior Mapping](#input-to-behavior-mapping)
- [Outputs](#outputs)
- [Report and Artifact Handling](#report-and-artifact-handling)
- [SBOM Generation](#sbom-generation)
- [Failure Logic](#failure-logic)
- [Usage Examples](#usage-examples)
  - [Filesystem Scan](#filesystem-scan)
  - [Container Image Scan](#container-image-scan)
  - [Configuration Scan](#configuration-scan)
- [SARIF Integration](#sarif-integration)
- [Compliance Benchmarking](#compliance-benchmarking)
- [Operational Best Practices](#operational-best-practices)
- [Security Governance Model](#security-governance-model)
- [References](#references)
- [License](#license)

---

## Overview

This GitHub Action integrates **Trivy** into CI/CD workflows to detect:

- OS and application vulnerabilities
- Infrastructure as Code misconfigurations
- Hardcoded secrets
- Compliance violations
- Dependency risks

Supported scan targets include:

- Filesystem
- Repository
- Container images
- Root filesystem
- Configuration files

The action is designed for enterprise security posture management and DevSecOps integration.

---

## Architecture and Execution Flow

The composite action executes in structured stages.

### 1. Scope Resolution

Based on `scan-scope`:

- `changed` → Detects modified files using `tj-actions/changed-files`
- `all` → Uses provided `scan_target`

Changed scope ensures efficient pull request scanning.

### 2. Database and Cache Preparation

- Restores Trivy database cache
- Installs fixed Trivy version
- Downloads vulnerability database with retry mechanism

### 3. Command Construction

The CLI command is dynamically built based on:

- Scan type
- Severity level
- Scanner selection
- Misconfiguration scanner selection
- Compliance benchmark
- Output format
- Timeout value

### 4. Scan Execution

Trivy runs with constructed parameters and:

- Generates structured output
- Writes report to file
- Captures exit code

### 5. Result Processing

- Sets workflow outputs
- Uploads artifact
- Uploads SARIF (if enabled)
- Optionally generates SBOM

---

## Scan Scope Behavior

### Changed Files Mode

Activated when:

```yaml
scan-scope: changed
```

Behavior:

- Retrieves list of changed files
- Still scans repository root (`.`)
- Optimizes workflow intent for PR validation
- Outputs report
- Sets exit code

Recommended for:

- Pull requests
- Incremental scanning
- Faster CI feedback

---

### Full Scope Mode

Activated when:

```yaml
scan-scope: all
```

Behavior:

- Uses explicit `scan_target`
- Scans entire directory, repo, or image
- Generates structured report
- Uploads artifact
- Optionally uploads SARIF

Recommended for:

- Main branch protection
- Scheduled compliance checks
- Release validation pipelines

---

## Scan Types

| Scan Type | Description |
|-----------|-------------|
| fs | Filesystem scan |
| repo | Repository scan |
| image | Container image scan |
| config | IaC and configuration scan |
| rootfs | Root filesystem scan |

Each type modifies Trivy CLI behavior internally.

---

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| scan_type | Type of scan | No | fs |
| scan-scope | Scope (`all` or `changed`) | No | changed |
| scan_target | Target path or image | No | . |
| severity | Minimum severity threshold | No | MEDIUM,HIGH,CRITICAL |
| ignore_unfixed | Ignore unfixed vulnerabilities | No | true |
| scanners | Enabled scanners | No | vuln |
| misconfig_scanners | Misconfiguration scanners | No | multiple defaults |
| format | Output format | No | sarif |
| timeout | Scan timeout | No | 10m |
| generate_sbom | Enable SBOM generation | No | false |
| sbom_format | SBOM format | No | spdx-json |
| compliance | Compliance benchmark | No | "" |
| upload-sarif | Upload SARIF to GitHub | No | true |

---

## Input-to-Behavior Mapping

| Input | Internal Behavior |
|-------|------------------|
| scan_type | Selects Trivy subcommand |
| scan-scope=changed | Uses repository root scan |
| scan-scope=all | Uses provided scan_target |
| severity | Maps to Trivy severity flags |
| ignore_unfixed | Adds `--ignore-unfixed` |
| scanners | Adds `--scanners` |
| misconfig_scanners | Adds `--misconfig-scanners` |
| format | Controls output file type |
| generate_sbom=true | Triggers SBOM generation |
| compliance | Adds `--compliance` flag |
| upload-sarif=true | Uploads SARIF file |

---

## Outputs

| Output | Description |
|--------|------------|
| scan_result | Exit code from Trivy |
| report_path | Path to generated report |

These outputs allow downstream workflow steps to evaluate results.

---

## Report and Artifact Handling

Reports are stored in:

```
security-results/trivy
```

File naming pattern:

```
trivy-results-<random>.<format>
```

Artifacts are uploaded using `actions/upload-artifact` with 7-day retention.

---

## SBOM Generation

When:

```yaml
generate_sbom: true
```

The action runs:

```
trivy fs --format <sbom_format>
```

Supported SBOM formats:

- cyclonedx
- spdx
- spdx-json

SBOM is stored in:

```
security-results/trivy/
```

This supports supply chain transparency and compliance initiatives.

---

## Failure Logic

Trivy exit codes are captured and surfaced via:

```
exit_code
```

Behavior:

- Non-zero exit code indicates findings
- Workflow does not immediately fail unless subsequent step enforces it
- SARIF upload still occurs

This supports:

- Monitoring mode
- Enforcement mode
- Gradual adoption strategy

---

## Usage Examples

### Filesystem Scan

```yaml
- name: Trivy Filesystem Scan
  uses: ./.github/actions/security/trivy
  with:
    scan_type: fs
    scan_target: .
    severity: HIGH,CRITICAL
```

---

### Container Image Scan

```yaml
- name: Trivy Image Scan
  uses: ./.github/actions/security/trivy
  with:
    scan_type: image
    scan_target: myimage:latest
```

---

### Configuration Scan

```yaml
- name: Trivy Config Scan
  uses: ./.github/actions/security/trivy
  with:
    scan_type: config
    scan_target: .
    compliance: docker-cis-1.6.0
```

---

## SARIF Integration

When:

```yaml
format: sarif
upload-sarif: true
```

Results are uploaded using:

- `github/codeql-action/upload-sarif`

Findings appear under:

GitHub → Security → Code scanning

Ensure workflow permissions include:

```yaml
permissions:
  security-events: write
```

---

## Compliance Benchmarking

You can enforce industry benchmarks:

```yaml
compliance: docker-cis-1.6.0
```

Supports:

- CIS Docker benchmarks
- Infrastructure compliance validation
- Policy enforcement in CI

---

## Operational Best Practices

- Use incremental scans for pull requests.
- Use full scans for protected branches.
- Enable SBOM generation for supply chain audits.
- Combine with dependency and SAST scanning.
- Monitor vulnerability database freshness.
- Tune severity thresholds to reduce noise.

---

## Security Governance Model

This action enables:

- Continuous vulnerability assessment
- Infrastructure security validation
- Supply chain transparency
- Compliance benchmarking
- Automated reporting
- GitHub-native security tracking

Suitable for:

- Enterprise DevSecOps programs
- Regulated environments
- Secure container pipelines
- Cloud-native deployments

---

## References

- [Trivy Documentation](https://github.com/aquasecurity/trivy)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)

---

## License

Apache License 2.0

