{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, fenix, crane, flake-parts, advisory-db, ... }:
    flake-parts.lib.mkFlake { inherit self inputs; } ({ withSystem, ... }: {
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

          commonBuildArgs = rec {
            src = craneLib.cleanCargoSource ./.;

            pname = "nix-rust-template";
            version = "v0.1.0";

            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = [ ];
          };

          cargoArtifacts = craneLib.buildDepsOnly ({ } // commonBuildArgs);
          clippy-check = craneLib.cargoClippy ({
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-features -- --deny warnings";
          }
          // commonBuildArgs);

          rust-fmt-check = craneLib.cargoFmt ({ inherit (commonBuildArgs) src; } // commonBuildArgs);

          test-check = craneLib.cargoNextest ({
            inherit cargoArtifacts;
            partitions = 1;
            partitionType = "count";
          }
          // commonBuildArgs);

          doc-check = craneLib.cargoDoc ({
            inherit cargoArtifacts;
          }
          // commonBuildArgs);

          audit-check = craneLib.cargoAudit ({
            inherit (commonBuildArgs) src;
            inherit advisory-db;
          }
          // commonBuildArgs);

          server-package = craneLib.buildPackage ({
            pname = "server";
            cargoExtraFlags = "--bin server";
            meta.mainProgram = "server";
            inherit cargoArtifacts;
          }
          // commonBuildArgs);

          client-package = craneLib.buildPackage ({
            pname = "client";
            cargoExtraFlags = "--bin client";
            meta.mainProgram = "client";
            inherit cargoArtifacts;
          }
          // commonBuildArgs);
        in
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = builtins.attrValues self.checks;
            buildInputs = [ rustToolchain ];
          };

          packages =
            {
              server = server-package;
              client = client-package;
            };

          checks =
            {
              inherit clippy-check rust-fmt-check test-check doc-check audit-check;
              inherit server-package client-package;
            };

          formatter = pkgs.nixpkgs-fmt;
        };
    });

  nixConfig = {
    extra-trusted-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}
