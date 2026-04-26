# nix-portable-playground

[numtide/devshell](https://github.com/numtide/devshell) で定義した開発環境を [DavHau/nix-portable](https://github.com/DavHau/nix-portable) でシングルバイナリに bundle して、Linux マシン (VPS など) に配るための雛形。

参考記事: [nix-portableで開発環境をシングルバイナリにする](https://comamoca.dev/blog/2026-04-08-setting-up-portable-dev-env-with-nix-portable/)

## 重要な前提

- nix-portable は **Linux 専用** (`x86_64-linux` / `aarch64-linux`)。macOS では bundle したバイナリは動かない。
- ローカル開発 (`nix develop`) は darwin でも OK。bundle 生成は Linux 環境が必要。

## ローカルで開発環境を試す (任意プラットフォーム)

```sh
nix develop
hello
go version
```

direnv 派なら `direnv allow` で `.envrc` の `use flake` が効く。

## Linux バイナリを作る

### 1. GitHub Actions (推奨)

`.github/workflows/build.yml` が `x86_64-linux` (`ubuntu-latest`) と `aarch64-linux` (`ubuntu-24.04-arm` 無料 ARM runner) で並行 bundle して artifact / release に上げる。

- main へ push / PR で artifact 生成
- リリースは [tagpr](https://github.com/Songmu/tagpr) 経由 (下記参照)

### 2. ローカル (Docker 経由)

`scripts/bundle-local.sh` で nixos/nix コンテナ内から bundle。Apple Silicon なら `aarch64-linux` はネイティブで高速、`x86_64-linux` は QEMU 経由で遅い。

```sh
./scripts/bundle-local.sh aarch64-linux   # 速い
./scripts/bundle-local.sh x86_64-linux    # 遅い (QEMU)
```

成果物: `./devshell-<system>`。Linux マシンに転送して `./devshell-<system> -c hello` 等で実行。

> 補足: bundle は単一バイナリだが、初回起動時に `$HOME/.nix-portable` に展開キャッシュを作る。

## インストール

最新 release から現在の CPU に合うバイナリを `~/.local/bin/nix-portable-playground` に入れる:

```sh
./install.sh
~/.local/bin/nix-portable-playground -c hello
```

`curl | bash` でも実行できる:

```sh
curl -fsSL https://raw.githubusercontent.com/upamune/nix-portable-playground/main/install.sh | bash
```

必要なら導入先や名前は上書きできる:

```sh
INSTALL_DIR=/usr/local/bin BIN_NAME=playground-devshell ./install.sh
```

### 3. nix-darwin の linux-builder (参考)

nix-darwin を使っているなら `nix.linux-builder.enable = true;` で aarch64-darwin から aarch64-linux 向けに直接 `nix bundle` できる。本リポジトリはこの構成は提供していない。

## リリース運用 (tagpr)

[Songmu/tagpr](https://github.com/Songmu/tagpr) で半自動リリース。

1. main に push されると `.github/workflows/tagpr.yml` が走り、次バージョンの release PR を作成 / 更新する
2. その PR を merge すると tagpr が `vX.Y.Z` タグを push し、release notes 付きの GitHub Release を作成
3. タグ push をトリガーに `.github/workflows/build.yml` が走り、`devshell-x86_64-linux` と `devshell-aarch64-linux` を Release に添付

設定ファイルは `.tagpr` (releaseBranch: main, vPrefix, release: true)。

初回リリース時は手動で `v0.0.0` を push しておくか、tagpr が作る最初の release PR を merge するだけで OK。

## ツールバージョン管理

- [aqua](https://aquaproj.github.io/) で `pinact` を管理 (`aqua.yaml`)
- `aqua i` でインストール → `aqua exec -- pinact run` で `.github/workflows/*.yml` の actions を SHA に pin
- CI (`.github/workflows/lint.yml`) で `pinact run --check` を実行し、未 pin の actions があれば失敗

## ファイル構成

```
flake.nix                       # numtide/devshell で devShell を定義
.envrc                          # direnv 用
aqua.yaml                       # pinact の version 固定
.pinact.yaml                    # pinact の設定
.github/workflows/build.yml     # Linux バイナリ bundle (x86_64 / aarch64) と Release 添付
.github/workflows/tagpr.yml     # tagpr による release PR 自動作成 / タグ打ち
.github/workflows/lint.yml      # pinact pin チェック
.tagpr                          # tagpr 設定
scripts/bundle-local.sh         # ローカル Docker 経由 bundle
```
