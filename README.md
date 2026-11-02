# Shopify Theme Check Compiled

[![Update Shopify Theme Check Environment](https://github.com/Yek-H/Shopify-Theme-Check-Compiled/actions/workflows/update-theme-check.yml/badge.svg)](https://github.com/Yek-H/Shopify-Theme-Check-Compiled/actions/workflows/update-theme-check.yml)
[![Latest release](https://img.shields.io/github/v/release/Yek-H/Shopify-Theme-Check-Compiled?display_name=tag)](../../releases/latest)

Automated, reproducible builds of the official [Shopify Theme Tools](https://github.com/Shopify/theme-tools) monorepo, focused on Shopify Theme Check.

Each release bundles Theme Tools, its installed dependencies, compiled outputs, and an exact snapshot of the [Shopify Liquid documentation](https://github.com/Shopify/theme-liquid-docs) for offline-friendly local use.

## Download

The latest build is always available from [**Releases**](../../releases/latest).

Each release contains:

- `Shopify-theme-tools-<version>-linux-x64-node22.tar.gz`
- a corresponding SHA-256 checksum file
- `BUILD_METADATA.json`

> [!NOTE]
> Releases target **Linux x64**, are built on **Ubuntu 24.04**, and use **Node.js 22**.

## Install

Install the latest release to `/opt/shopify-theme-tools`:

```bash
bash scripts/install-latest.sh /opt/shopify-theme-tools
```

Or choose another destination:

```bash
bash scripts/install-latest.sh "$HOME/shopify-theme-tools"
```

Then run Theme Check:

```bash
/path/to/shopify-theme-tools/theme-check-local /absolute/path/to/theme
```

The `theme-check-local` wrapper uses the bundled Liquid documentation snapshot, allowing the downloaded environment to run without access to GitHub.

## What it tracks

The updater monitors two independent upstream sources:

- **Theme Check / Theme Tools:** the latest stable `@shopify/theme-check-node` version published to npm.
- **Shopify Liquid documentation:** the latest `main` commit from [Shopify/theme-liquid-docs](https://github.com/Shopify/theme-liquid-docs).

A new build is produced only when either upstream value changes, unless a manual run is forced.

## Automatic updates

The workflow runs every day at **06:00 UTC** and can also be launched manually from **Actions → Update Shopify Theme Check Environment**.

Manual runs can use the `force` option to rebuild even when the detected upstream versions have not changed.

## Build process

The GitHub Actions workflow:

1. Detects the latest stable Theme Check version.
2. Detects the latest Shopify Liquid documentation commit.
3. Checks out the matching official `Shopify/theme-tools` release tag with recursive submodules.
4. Clones `Shopify/theme-liquid-docs` at the exact detected commit.
5. Reads the required pnpm version from Theme Tools' own `packageManager` field.
6. Installs dependencies with `pnpm install --frozen-lockfile`.
7. Builds the complete monorepo.
8. Runs type checking, unit tests, and format validation.
9. Runs a Theme Check smoke test against a minimal Shopify theme.
10. Packages Theme Tools, its installed dependencies, compiled outputs, and the exact Liquid documentation snapshot.
11. Publishes both a GitHub Actions artifact and a permanent GitHub Release with SHA-256 checksums and provenance metadata.
12. Uses the release tag as the update state, skipping scheduled rebuilds when the same Theme Check version and Liquid documentation commit are already published.

Browser downloads are skipped because they are not required for the Theme Check build.

## Release contents

The archive contains:

```text
theme-tools/
theme-liquid-docs/
theme-check-local
BUILD_METADATA.json
```

## Reproducibility

Every release records:

- Theme Check version
- Theme Tools source commit
- Liquid docs commit
- Liquid grammar submodule revision
- Node.js version
- pnpm version
- build timestamp
- target OS/architecture

The workflow never copies dependencies or compiled output from an older Theme Check installation. Every upstream change is rebuilt from the official lockfile and source repositories.
