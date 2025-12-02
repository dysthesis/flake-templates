{
  perSystem = {
    craneLib,
    pkgs,
    commonArgs,
    cargoArtifacts,
    ...
  }: let
    inherit (pkgs) callPackage;
  in {
    packages = rec {
      template = callPackage ./template {
        inherit
          craneLib
          pkgs
          commonArgs
          cargoArtifacts
          ;
      };

      default = template;
    };
  };
}
