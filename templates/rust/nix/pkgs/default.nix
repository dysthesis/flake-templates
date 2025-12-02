{
  perSystem =
    {
      craneLib,
      pkgs,
      src,
      commonArgs,
      cargoArtifacts,
      lib,
      inputs,
      inputs',
      charonToolchain,
      ...
    }:
    let
      inherit (pkgs) callPackage system;
    in
    {
      packages = rec {
        package = callPackage ./package {
          inherit
            craneLib
            pkgs
            commonArgs
            cargoArtifacts
            ;
        };

        lean-translation = callPackage ./lean-translation {
          inherit lib charonToolchain craneLib;
          inherit (inputs'.aeneas.packages) aeneas charon;
          inherit src;
        };

        default = package;
      };
    };
}
