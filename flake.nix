{
  description = "nix-portable playground - bundle a devShell into a single binary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, devshell, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
        starshipConfig = pkgs.writeText "starship.toml" (builtins.readFile ./config/starship.toml);
        aiCliWrapper = tool: pkg: exe:
          pkgs.writeShellScriptBin tool ''
            set -euo pipefail

            runtime_root="''${XDG_STATE_HOME:-$HOME/.local/state}/nix-portable-playground"
            mise_root="$runtime_root/mise"
            npm_root="$runtime_root/npm"
            config_dir="$mise_root/config"
            data_dir="$mise_root/data"
            cache_dir="$mise_root/cache"
            state_dir="$mise_root/state"
            global_config_file="$config_dir/config.toml"

            mkdir -p "$config_dir" "$data_dir" "$cache_dir" "$state_dir" "$npm_root/cache"
            if [ ! -f "$global_config_file" ]; then
              cat >"$global_config_file" <<'EOF'
[settings]
idiomatic_version_file_enable_tools = []
EOF
            fi

            export MISE_GLOBAL_CONFIG_FILE="$global_config_file"
            export MISE_CONFIG_DIR="$config_dir"
            export MISE_DATA_DIR="$data_dir"
            export MISE_CACHE_DIR="$cache_dir"
            export MISE_STATE_DIR="$state_dir"
            export NPM_CONFIG_CACHE="$npm_root/cache"

            exec ${pkgs.mise}/bin/mise x ${pkg} -- ${exe} "$@"
          '';
        claudeWrapper = aiCliWrapper "claude" "npm:@anthropic-ai/claude-code@latest" "claude";
        claudeCodeWrapper = aiCliWrapper "claudecode" "npm:@anthropic-ai/claude-code@latest" "claude";
        codexWrapper = aiCliWrapper "codex" "npm:@openai/codex@latest" "codex";
        opencodeWrapper = aiCliWrapper "opencode" "github:anomalyco/opencode@latest" "opencode";
        piWrapper = aiCliWrapper "pi" "npm:@mariozechner/pi-coding-agent@latest" "pi";
        zshDotDir = pkgs.symlinkJoin {
          name = "playground-zdotdir";
          paths = [
            (pkgs.writeTextDir ".zshenv" ''
              export SHELL=${pkgs.zsh}/bin/zsh
            '')
            (pkgs.writeTextDir ".zshrc" ''
              setopt prompt_subst

              export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
              mkdir -p "$XDG_CACHE_HOME/zsh"

              alias ls='eza'
              alias ll='eza -la'
              alias lt='eza --tree'
              alias cat='bat'

              export STARSHIP_CONFIG=${starshipConfig}
              autoload -Uz compinit
              compinit -d "$XDG_CACHE_HOME/zsh/.zcompdump"

              eval "$(${pkgs.starship}/bin/starship init zsh)"
              eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
              eval "$(${pkgs.atuin}/bin/atuin init zsh)"
              export PATH="$DEVSHELL_DIR/bin:$PATH"
            '')
          ];
        };
      in {
        devShells.default = pkgs.devshell.mkShell {
          name = "playground";

          # nix-portable で bundle するために pkgs.nix を含める必要がある
          packages = with pkgs; [
            nix
            git
            zsh
            starship
            zoxide
            atuin
            eza
            fzf
            git-lfs
            delta
            gh
            direnv
            tmux
            tree
            curl
            wget
            unzip
            mise
            nodejs_22
            nerd-fonts.jetbrains-mono
            ripgrep
            jq
            fd
            bat
            claudeWrapper
            claudeCodeWrapper
            codexWrapper
            opencodeWrapper
            piWrapper
          ];

          commands = [
            {
              name = "hello";
              help = "say hello";
              command = "echo 'Hello from portable devshell!'";
            }
          ];

          devshell.interactive.zsh.text = ''
            if [[ -z "''${ZSH_VERSION:-}" && -z "''${DEVSHELL_ZSH_INIT:-}" ]]; then
              export DEVSHELL_ZSH_INIT=1
              export SHELL=${pkgs.zsh}/bin/zsh
              export ZDOTDIR=${zshDotDir}
              exec ${pkgs.zsh}/bin/zsh -i
            fi
          '';
        };
      });
}
