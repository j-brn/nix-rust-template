{ pkgs, lib, ... }:

pkgs.stdenv.mkDerivation {
  name = "docbook";
  src = ./.;

  nativeBuildInputs = [ pkgs.mdbook ];

  buildPhase = ''
    mdbook build
  '';

  installPhase = ''
    mv book $out
  '';
}