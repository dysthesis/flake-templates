{
  perSystem = {
    craneLib,
    pkgs,
    commonArgs,
    cargoArtifacts,
    lib,
    inputs',
    charonToolchain,
    lake2nix,
    ...
  }: let
    inherit (pkgs) callPackage;
  in {
    packages = rec {
      package = callPackage ./package {
        inherit
          craneLib
          pkgs
          commonArgs
          cargoArtifacts
          ;
      };

      aeneas-lean-backend = callPackage ./aeneas-lean-backend {
        inherit lake2nix;
      };

      lean-translation = callPackage ./lean-translation {
        inherit lib charonToolchain craneLib aeneas-lean-backend lake2nix;
        inherit (inputs'.aeneas.packages) aeneas charon;
        src = ../../.;
      };

      default = package;
    };
  };
}
