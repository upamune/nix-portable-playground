#!/usr/bin/env bash
# ローカル (aarch64-darwin) から linux 向けに devShell を nix-portable で bundle する。
#
# 仕組み: nixos/nix の Linux コンテナを起動し、コンテナ内で `nix bundle` を実行する。
# - aarch64-linux ターゲット: Apple Silicon ならネイティブ実行で高速
# - x86_64-linux ターゲット: QEMU エミュレーション経由で遅い
#
# 使い方:
#   ./scripts/bundle-local.sh                  # デフォルト: aarch64-linux
#   ./scripts/bundle-local.sh x86_64-linux
#   ./scripts/bundle-local.sh aarch64-linux

set -euo pipefail

SYSTEM="${1:-aarch64-linux}"

case "$SYSTEM" in
  aarch64-linux) PLATFORM="linux/arm64" ;;
  x86_64-linux)  PLATFORM="linux/amd64" ;;
  *)
    echo "unsupported system: $SYSTEM (expected aarch64-linux or x86_64-linux)" >&2
    exit 1
    ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="devshell-${SYSTEM}"

echo "==> bundling ${SYSTEM} via Docker (${PLATFORM})"

docker run --rm \
  --platform "$PLATFORM" \
  -v "$REPO_ROOT:/work" \
  -w /work \
  -e SYSTEM="$SYSTEM" \
  nixos/nix:latest \
  sh -c '
    set -eu
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
    rm -rf devshell devshell-${SYSTEM}
    nix bundle \
      --bundler github:DavHau/nix-portable#zstd-max \
      -o devshell \
      ".#devShells.${SYSTEM}.default"
    cp -L devshell/bin/devshell "devshell-${SYSTEM}"
    chmod +w "devshell-${SYSTEM}"
  '

echo "==> done: ${REPO_ROOT}/${OUT}"
ls -lh "${REPO_ROOT}/${OUT}"

cat <<EOF

bundle を試すには (Linux マシン or 同じコンテナ内で):
  ./${OUT} -c hello
  ./${OUT} -c go version
EOF
