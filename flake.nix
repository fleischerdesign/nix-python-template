{
  description = "A reproducible Python development environment with modern tooling.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      templates.default = {
        path = ./.;
        description = "A reproducible Python development environment with modern tooling";
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.python313
            pkgs.uv
            pkgs.ruff
            pkgs.pyright
          ];
          shellHook = ''
            echo "Entering Python development environment..."
            echo "Available tools: python, uv, ruff, pyright"
          '';
        };
      }
    );
}
