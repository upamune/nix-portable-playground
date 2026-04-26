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
      in {
        devShells.default = pkgs.devshell.mkShell {
          name = "playground";

          # nix-portable で bundle するために pkgs.nix を含める必要がある
          packages = with pkgs; [
            nix
            zsh
            mise
            ripgrep
            jq
            fd
            bat
          ];

          commands = [
            {
              name = "hello";
              help = "say hello";
              command = "echo 'Hello from portable devshell!'";
            }
          ];
        };
      });
}
