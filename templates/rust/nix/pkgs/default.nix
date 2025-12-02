{
  craneLib,
  pkgs,
  commonArgs,
  cargoArtifacts,
  ...
}: let
  inherit (pkgs) callPackage;
in rec {
  template = callPackage ./template {
    inherit
      craneLib
      pkgs
      commonArgs
      cargoArtifacts
      ;
  };

  default = template;
}
