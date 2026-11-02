# Shopify Theme Check Compiled

A clean, automated build of https://github.com/Shopify/theme-tools.

This repository is dedicated to producing a clean, reproducible and automatically updated local build of the official [Shopify Theme Tools](https://github.com/Shopify/theme-tools) monorepo.

It no longer contains the previous MangaFans project files.

## What it tracks

The updater monitors two independent upstream sources:

- **Theme Check / Theme Tools:** the latest stable `@shopify/theme-check-node` version published to npm.
- **Shopify Liquid documentation:** the latest `main` commit from [Shopify/theme-liquid-docs](https://github.com/Shopify/theme-liquid-docs).

A new build is produced only when either upstream value changes, unless a manual run is forced.

## Build environment

The GitHub Actions build:

1. Detects the latest stable Theme Check version.
2. Detects the latest Shopify Liquid documentation commit.
3. Checks out the matching official `Shopify/theme-tools` release tag with recursive submodules.
4. Clones `Shopify/theme-liquid-docs` at the exact detected commit.
5. Reads the required pnpm version from Theme Tools' own `packageManager` field.
6. Installs dependencies with `pnpm install --frozen-lockfile`.
7. Builds the complete monorepo.
8. Runs type checking, unit tests and format validation.
9. Runs a real Theme Check smoke test against a minimal Shopify theme.
10. Packages Theme Tools, its installed dependencies, compiled outputs and the exact Liquid docs snapshot.
11. Publishes both a GitHub Actions artifact and a permanent GitHub Release with SHA-256 checksums and provenance metadata.
12. Uses the release tag itself as the update state; if the same Theme Check version and Liquid docs commit are already published, the scheduled run skips rebuilding.

The runner is pinned to **Ubuntu 24.04 / Linux x64** and uses **Node.js 22**. Browser downloads are skipped because they are not required for the Theme Check build.

## Automatic updates

The workflow runs every day at **06:00 UTC** and can also be launched manually from **Actions → Update Shopify Theme Check Environment**.

A manual run has a `force` option for rebuilding even if the detected Theme Check version and Liquid docs commit have not changed.

## Download the latest environment

Each successful update creates a permanent GitHub Release containing:

- `Shopify-theme-tools-<version>-linux-x64-node22.tar.gz`
- matching `.sha256`
- `BUILD_METADATA.json`

The archive contains:

```text
theme-tools/
theme-liquid-docs/
theme-check-local
BUILD_METADATA.json
```

The `theme-check-local` wrapper points Theme Check at the bundled Liquid documentation snapshot so the downloaded environment works even when the destination machine cannot reach GitHub.

## Install the latest release

On Linux x64:

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
