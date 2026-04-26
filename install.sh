#!/usr/bin/env bash

set -euo pipefail

REPO="${REPO:-upamune/nix-portable-playground}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
BIN_NAME="${BIN_NAME:-nix-portable-playground}"
API_BASE="${API_BASE:-https://api.github.com}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

need_cmd curl
need_cmd uname
need_cmd mktemp
need_cmd chmod
need_cmd mkdir
need_cmd mv
need_cmd rm
need_cmd cmp

if [ "$(uname -s)" != "Linux" ]; then
  echo "error: this installer supports Linux only" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64|amd64)
    ASSET_NAME="devshell-x86_64-linux"
    ;;
  aarch64|arm64)
    ASSET_NAME="devshell-aarch64-linux"
    ;;
  *)
    echo "error: unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

LATEST_JSON="$TMP_DIR/latest-release.json"
curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --retry 3 \
  --output "$LATEST_JSON" \
  "$API_BASE/repos/$REPO/releases/latest"

TAG_NAME="$(
  sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$LATEST_JSON" | head -n 1
)"

if [ -z "$TAG_NAME" ]; then
  echo "error: failed to determine latest release tag for $REPO" >&2
  exit 1
fi

if ! grep -q "\"name\":[[:space:]]*\"$ASSET_NAME\"" "$LATEST_JSON"; then
  echo "error: latest release $TAG_NAME does not contain asset $ASSET_NAME" >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG_NAME/$ASSET_NAME"
DEST_PATH="$INSTALL_DIR/$BIN_NAME"
TMP_BIN="$TMP_DIR/$BIN_NAME"

mkdir -p "$INSTALL_DIR"

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --retry 3 \
  --output "$TMP_BIN" \
  "$DOWNLOAD_URL"

chmod 0755 "$TMP_BIN"

if [ -f "$DEST_PATH" ] && cmp -s "$TMP_BIN" "$DEST_PATH"; then
  echo "$BIN_NAME is already up to date ($TAG_NAME) at $DEST_PATH"
  exit 0
fi

mv -f "$TMP_BIN" "$DEST_PATH"
echo "installed $BIN_NAME $TAG_NAME to $DEST_PATH"

