{
  description = "A reproducible Python development environment with modern tooling.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Granular builder helper for consumer flakes (Way A)
      mkPythonShell =
        {
          pkgs,
          pythonPackage ? pkgs.python313,
          enableCBuildTools ? true,
          extraPackages ? [ ],
          env ? { },
          shellHook ? "",
        }:
        let
          baseShell = pkgs.mkShell {
            packages =
              [
                pythonPackage
                pkgs.uv
                pkgs.ruff
                pkgs.pyright
              ]
              ++ (if enableCBuildTools then [ pkgs.gcc pkgs.gnumake pkgs.stdenv.cc.cc.lib ] else [ ])
              ++ extraPackages;
            shellHook = ''
              echo "Entering Python development environment..."
              echo "Available tools: python, uv, ruff, pyright"
            '';
          };
        in
        baseShell.overrideAttrs (oldAttrs: {
          env = oldAttrs.env or { } // env;
          shellHook = (oldAttrs.shellHook or "") + "\n" + shellHook;
        });
    in
    {
      # Granular Library helper functions for consumer flakes
      lib = {
        inherit mkPythonShell;
      };

      # Scaffolding templates for 'nix flake init' (Way B)
      templates = {
        default = {
          path = ./.;
          description = "A reproducible Python development environment with modern tooling";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        defaultShell = mkPythonShell { inherit pkgs; };
      in
      {
        devShells = {
          default = defaultShell;
        };

        checks = {
          default = defaultShell;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "python-env-info" ''
              echo "=== Python Nix Development Environment ==="
              ${pkgs.python313}/bin/python --version
              ${pkgs.uv}/bin/uv --version
            '';
          };
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
