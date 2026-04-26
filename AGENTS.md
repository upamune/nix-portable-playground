# Repository Guidelines

## Project Structure & Module Organization

This repository is a small Nix flake for bundling a portable Linux dev shell. Keep the top level flat:

- `flake.nix`: defines `devShells.default` and bundled tools.
- `scripts/bundle-local.sh`: builds `devshell-<system>` through Docker.
- `install.sh`: installs the latest released bundle for the current Linux CPU.
- `.github/workflows/`: CI for bundle builds, smoke tests, linting, and tag-based releases.
- `aqua.yaml` and `aqua-checksums.json`: pinned CLI tooling for CI support.

Generated artifacts such as `devshell-x86_64-linux` should stay out of version control.

## Build, Test, and Development Commands

- `nix develop`: enter the local dev shell on any supported host.
- `hello`: verify the shell command exported by `flake.nix`.
- `./scripts/bundle-local.sh aarch64-linux`: build a Linux bundle locally via Docker.
- `./scripts/bundle-local.sh x86_64-linux`: build the x86_64 bundle; slower on Apple Silicon because it uses emulation.
- `./devshell-aarch64-linux hello`: smoke-test a generated bundle.
- `aqua i`: install pinned helper tools such as `pinact`.
- `pinact run --check`: validate that GitHub Actions are SHA-pinned, matching CI.

## Coding Style & Naming Conventions

Use `bash` with `set -euo pipefail` for scripts and keep them POSIX-lean unless Bash is required. Prefer 2-space indentation in Nix and shell blocks, matching existing files. Use clear, lowercase file names with hyphens for scripts (`bundle-local.sh`). Name release artifacts `devshell-<system>` exactly, because CI and `install.sh` depend on that pattern.

## Testing Guidelines

There is no standalone unit test suite today. Validation is done through shell checks and bundle smoke tests:

- run `nix develop` and exercise the exported commands;
- build the target bundle locally;
- run the bundle with `hello`, `zsh --version`, and `mise --version`.

If you change `flake.nix`, `install.sh`, or the bundling flow, include at least one manual smoke test in the PR notes.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `fix portable devshell entrypoint` and `add installer script`. Keep subjects concise, lowercase is acceptable, and describe one change per commit. PRs should state what changed, how it was tested, and whether release behavior or bundled artifact names were affected. Link related issues when applicable.
