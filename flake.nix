{
  description = "Badflyer.com";
  nixConfig.bash-prompt = "\[nix-badflyer-shell\]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        inputs = [
          pkgs.mdbook
          pkgs.git
        ];

        builder = pkgs.stdenv.mkDerivation {
          name = "badflyer";
          src = ./.;
          buildInputs = inputs;
          buildPhase = ''
            mdbook build
          '';
          installPhase = ''
            mkdir $out
            cp -R book/* $out
          '';
        };

      in {
        devShell = pkgs.mkShell {
          buildInputs = inputs;
          };

        packages.default = builder;
        defaultPackage = builder;
        checks.default = builder;
      });
}
