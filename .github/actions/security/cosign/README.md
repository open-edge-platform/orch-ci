# Sign Image or Binary with Cosign GitHub Action

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A GitHub Action to **sign container images or binaries using
[Cosign](https://docs.sigstore.dev/quickstart/quickstart-cosign/)** from
[Sigstore](https://github.com/sigstore/cosign). This action automates
**signing, verification, and artifact handling** in CI/CD workflows.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Sign an Image](#sign-an-image)
  - [Sign a Binary](#sign-a-binary)
- [Inputs](#inputs)
- [Outputs / Artifacts](#outputs--artifacts)
- [How it Works](#how-it-works)
- [References](#references)
- [License](#license)

---

## Features

- Sign **container images** or **binaries** using Cosign.
- Supports **keyless signing** directly to container registries.
- Automatically **verifies signatures** using OIDC-issued certificates.
- Downloads and uploads Cosign artifacts (signature, certificate, bundle,
  attestation) as GitHub artifacts.
- Flexible for **prod** and **non-prod** environments.
- Works seamlessly with GitHub Actions workflows.

---

## Prerequisites

- GitHub repository with GitHub Actions enabled.
- [GitHub token](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
  with permissions for container registry login.
- Docker installed if signing container images.
- Cosign is automatically installed by this action (no manual installation
  required).

---

## Usage

Create a workflow file in `.github/workflows/sign.yml`:

```yaml
name: Sign Artifact

on:
  push:
    branches:
      - main

jobs:
  sign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sign with Cosign
        uses: your-org/your-cosign-action@main
        with:
          target: 'image'                 # 'image' or 'binary'
          artifact: 'ghcr.io/org/app:tag' # Full container image or binary path
          environment: 'prod'             # Optional, default: 'non-prod'
          gh_token: ${{ secrets.GITHUB_TOKEN }}
```

### Sign an Image

```yaml
with:
  target: 'image'
  artifact: 'ghcr.io/org/app:tag'
```

**Steps performed:**

1. Logs into GitHub Container Registry using `gh_token`.
2. Signs the image keylessly with Cosign.
3. Downloads signature, certificate, and attestation artifacts.
4. Verifies the signature using OIDC-issued certificates.
5. Uploads artifacts to GitHub Actions.

---

### Sign a Binary

```yaml
with:
  target: 'binary'
  artifact: './bin/app'
```

**Steps performed:**

1. Signs the binary locally using Cosign.
2. Generates the following artifacts:
   - `cosign.sig` — signature file
   - `cosign.cert` — certificate file
   - `cosign.bundle.json` — signing bundle
3. Verifies the signature using OIDC-issued certificate.
4. Uploads artifacts to GitHub Actions.

---

## Inputs

| Input        | Description                                                   | Required | Default      |
|--------------|---------------------------------------------------------------|----------|--------------|
| `target`     | Type of artifact to sign: `image` or `binary`                | ✅       | —            |
| `artifact`   | Full image reference (e.g., `ghcr.io/org/app:tag`) or path   | ✅       | —            |
| `environment`| Environment to sign for (`prod` or `non-prod`)               | ❌       | `non-prod`   |
| `gh_token`   | GitHub token for registry authentication                     | ✅       | —            |

---

## Outputs / Artifacts

All signatures, certificates, bundles, and attestations are uploaded as
GitHub Actions artifacts with a unique suffix, e.g., `cosign-image-3f2a1b`.

| Artifact                | Description |
|-------------------------|------------|
| `cosign.sig`            | Signature of the artifact |
| `cosign.cert`           | Certificate issued by Cosign |
| `cosign.bundle.json`    | Signing bundle with metadata |
| `cosign.att`            | Attestation for container images |

---

## How it Works

1. **Setup Cosign** — Installs Cosign version `v3.0.2`.
2. **Login (Images only)** — Authenticates to GitHub Container Registry using
   `gh_token`.
3. **Signing**:
   - **Image**: Keyless signing directly to the registry.
   - **Binary**: Local signing with output files (`sig`, `cert`, `bundle`).
4. **Fetch Artifacts** (Images only) — Downloads signature, certificate, and
   attestation.
5. **Verify Signature** — Ensures authenticity using OIDC-issued certificates.
6. **Upload Artifacts** — All Cosign artifacts are uploaded to GitHub Actions
   for traceability.

---

## References

- [Cosign Quickstart](https://docs.sigstore.dev/quickstart/quickstart-cosign/)
- [Cosign GitHub Repository](https://github.com/sigstore/cosign)
- [Sigstore Project](https://sigstore.dev/)

---

## License

This project is licensed under the **Apache 2.0 License**. See
[LICENSE](./LICENSE) for details.

---

> 🔒 **Security Note:** Keyless signing uses ephemeral OIDC tokens. No long-lived
> secrets are required in your repository.
