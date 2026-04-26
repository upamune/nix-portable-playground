# nix-portable-playground

Linux マシンに配ってすぐ使える、ポータブルな開発環境です。  
このリポジトリでは `numtide/devshell` で定義した環境を `nix-portable` で単一バイナリにまとめています。

受け取った人は Nix を事前に入れなくても、配布されたバイナリ 1 本で同じツール群を起動できます。

参考記事: [nix-portableで開発環境をシングルバイナリにする](https://comamoca.dev/blog/2026-04-08-setting-up-portable-dev-env-with-nix-portable/)

## これは何か

このバイナリを使うと、Linux 上で次のような開発ツール入りシェルを起動できます。

- `zsh`
- `mise`
- `ripgrep`
- `jq`
- `fd`
- `bat`

サンプルとして `hello` コマンドも入っています。

```sh
./devshell-x86_64-linux hello
```

## 使う人向け

### 1. インストールする

最新 release から現在の CPU に合うバイナリを取得して `~/.local/bin` に入れます。

```sh
./install.sh
~/.local/bin/nix-portable-playground hello
```

`curl | bash` でも導入できます。

```sh
curl -fsSL https://raw.githubusercontent.com/upamune/nix-portable-playground/main/install.sh | bash
```

導入先やコマンド名を変えたい場合:

```sh
INSTALL_DIR=/usr/local/bin BIN_NAME=playground-devshell ./install.sh
```

### 2. 実行する

インストール後は、通常のコマンドのように呼べます。

```sh
nix-portable-playground hello
nix-portable-playground zsh --version
nix-portable-playground mise --version
```

初回起動時には `$HOME/.nix-portable` に展開キャッシュを作成します。

### 3. 対応環境を確認する

- Linux 専用です
- 対応 CPU は `x86_64` と `aarch64` です
- macOS では bundle 済みバイナリは動きません

## 作る人向け

### ローカルで dev shell を試す

配布前に、まず flake の dev shell をそのまま確認できます。

```sh
nix develop
hello
```

`direnv` を使う場合は `direnv allow` を実行してください。

### ローカルで Linux バイナリを作る

Docker 経由で bundle できます。

```sh
./scripts/bundle-local.sh aarch64-linux
./scripts/bundle-local.sh x86_64-linux
```

生成物は `./devshell-<system>` です。

```sh
./devshell-aarch64-linux hello
./devshell-aarch64-linux zsh --version
```

補足:

- Apple Silicon では `aarch64-linux` が高速です
- `x86_64-linux` は QEMU 経由なので遅くなります

## CI とリリース

GitHub Actions では次を自動実行します。

- `main` への push / pull request で bundle を build
- `hello` / `zsh --version` / `mise --version` を smoke test
- `v*` タグでは release にバイナリを添付

リリースは `tagpr` ベースです。`main` への push で release PR を更新し、その PR を merge するとタグと GitHub Release が作られます。

## 関連ファイル

```text
flake.nix                   dev shell 定義
install.sh                  利用者向けインストーラ
scripts/bundle-local.sh     ローカル bundle
.github/workflows/build.yml bundle と smoke test
.github/workflows/tagpr.yml release PR とタグ運用
.github/workflows/lint.yml  pinact チェック
aqua.yaml                   開発用 CLI ツールの固定
```
