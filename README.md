# nix-rust-template

## Features

- workspace support
- build with [crane](https://github.com/nix-rust/nix)
- most recent and/or custom rust toolchain with [fenix](https://github.com/nix-community/fenix)
- cargo clippy, fmt, test, doc and audit as flake checks
- complete Github CI with automatic lockfile updates, flake checks, build
- automatic bundling of releases (deb, rpm, pacman, AppImage, Docker) for aarch64-linux and x86_64-linux

## Prerequisites

- [Nix](https://github.com/NixOS/nix) has to be installed and
  [flakes and the experimental nix command have to be enabled](https://nixos.wiki/wiki/Flakes#Enable_flakes)
- (optional) install and setup [direnv](https://direnv.net/) to automatically enter the dev shell in this directory
- (optional) obtain a [personal GitHub access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  with read and write access on this repository for automatic flake updates. Automatic flake updates also work without
  a personal access token, but pipelines won't trigger for the update pull requests if you use the standard GitHub Bot user


## Getting started

- click "use this template" to create your repository
- rename or remove the existing crates
  - rename or recreate all crates under `crates/` with names of your choosing
  - in `Cargo.toml` change the paths in the `[members]` field to the crates you just created/renamed
  - in `.github/workflows/ci.yml` replace/delete "client" and "server" in the job matrix for "bundle" amd "build"
  - in `flake.nix`
    - replace/delete "client-package" and "server-package" with "$name-package"
    - replace/delete `packages.client` and `packages.server` to `packages.$name`
    - replace/delete the `inherit client-package server-package` in the devShell section with the new names and
      add/remove any crates you added/removed
- create the repository secret `GH_TOKEN_FOR_UPDATES` with your personal GitHub access token or replace
  `${{ secrets.GH_TOKEN_FOR_UPDATES }}` with `${{ secrets.GITHUB_TOKEN }}` in `.github/workflows/update.yml`
- (optional) enable the [Renovate bot](https://github.com/marketplace/renovate) for automatic rust and actions dependency updates
  or delete `renovate.json`
- (optional) allow direnv to run: `direnv allow`


## Planned Features

- [ ] darwin support
- [ ] cross compilation for windows
- [ ] code coverage checks
- [ ] actions/scripts to automate most of [Getting Started]
