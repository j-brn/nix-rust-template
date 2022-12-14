{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, fenix, crane, flake-parts, advisory-db, ... }:
    flake-parts.lib.mkFlake { inherit self; } ({ withSystem, ... }: {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = { lib, config, self', inputs', pkgs, system, ... }:
        let
          rustToolchain = with fenix.packages.${system};
            combine [
              minimal.rustc
              minimal.cargo
              stable.rustfmt
              stable.clippy
              stable.rust-src
            ];

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
          src = craneLib.cleanCargoSource ./.;

          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = [ ];

          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src buildInputs nativeBuildInputs;
          };

          my-crate = craneLib.buildPackage {
            inherit cargoArtifacts src buildInputs nativeBuildInputs;
          };
        in
        {
          packages.default = my-crate;
          apps.default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/my-crate";
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = builtins.attrValues self.checks;
          };

          checks =
            {
              inherit my-crate;

              my-crate-clippy = craneLib.cargoClippy {
                inherit cargoArtifacts src buildInputs nativeBuildInputs;
                cargoClippyExtraArgs = "--all-targets -- --deny warnings";
              };

              my-crate-doc = craneLib.cargoDoc { inherit cargoArtifacts src buildInputs nativeBuildInputs; };
              my-crate-fmt = craneLib.cargoFmt { inherit src; };
              my-crate-audit = craneLib.cargoAudit { inherit src advisory-db; };
            };

          formatter = pkgs.nixpkgs-fmt;
        };
    });
}
