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
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
          rustToolchain = fenix.packages.${system}.stable.withComponents [
            "rustc"
            "cargo"
            "rustfmt"
            "clippy"
            "rust-src"
          ];

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
          src = craneLib.cleanCargoSource ./.;

          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = [ ];

          cargoArtifacts = craneLib.buildDepsOnly {
            inherit src buildInputs nativeBuildInputs;
          };

          my-crate = craneLib.buildPackage {
            name = "my-crate";
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

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://nix-rust-template.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-rust-template.cachix.org-1:djhhKdQkilYrrV/GLYHq38Y+6hR4NAeT1NabRg6Cb7k="
    ];
  };
}
