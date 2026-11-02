#!/usr/bin/env bash
set -euo pipefail

REPO="Yek-H/shopifymanga"
DEST="${1:-$HOME/shopify-theme-tools}"

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum is required" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

API="https://api.github.com/repos/$REPO/releases/latest"
RELEASE_JSON="$TMP/release.json"

curl -fsSL "$API" -o "$RELEASE_JSON"

BUNDLE_URL="$(jq -r '.assets[] | select(.name | test("^Shopify-theme-tools-.*-linux-x64-node22\\.tar\\.gz$")) | .browser_download_url' "$RELEASE_JSON" | head -n1)"
CHECKSUM_URL="$(jq -r '.assets[] | select(.name | test("^Shopify-theme-tools-.*-linux-x64-node22\\.tar\\.gz\\.sha256$")) | .browser_download_url' "$RELEASE_JSON" | head -n1)"

if [[ -z "$BUNDLE_URL" || "$BUNDLE_URL" == "null" || -z "$CHECKSUM_URL" || "$CHECKSUM_URL" == "null" ]]; then
  echo "Latest release does not contain the expected Linux x64 bundle." >&2
  exit 1
fi

BUNDLE="$TMP/$(basename "$BUNDLE_URL")"
CHECKSUM="$BUNDLE.sha256"

curl -fL "$BUNDLE_URL" -o "$BUNDLE"
curl -fL "$CHECKSUM_URL" -o "$CHECKSUM"

(
  cd "$TMP"
  sha256sum -c "$(basename "$CHECKSUM")"
)

rm -rf "$DEST"
mkdir -p "$DEST"
tar -xzf "$BUNDLE" -C "$DEST"

echo "Installed at: $DEST"
echo "Run:"
echo "  $DEST/theme-check-local /absolute/path/to/shopify-theme"
