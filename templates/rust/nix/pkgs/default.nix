{
  perSystem =
    {
      craneLib,
      pkgs,
      commonArgs,
      cargoArtifacts,
      lib,
      inputs',
      charonToolchain,
      lake2nix,
      ...
    }:
    let
      inherit (pkgs) callPackage;
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

        proofwidgets = callPackage ./proofwidgets { inherit lake2nix; };

        mathlib = callPackage ./mathlib { inherit pkgs; };

        aeneas-lean-backend = callPackage ./aeneas-lean-backend {
          inherit lake2nix proofwidgets;
        };

        lean-translation = callPackage ./lean-translation {
          inherit
            lib
            charonToolchain
            craneLib
            aeneas-lean-backend
            lake2nix
            ;
          inherit (inputs'.aeneas.packages) aeneas charon;
          src = ../../.;
        };

        proofs = callPackage ./proofs {
          inherit pkgs lib lean-translation;
          aeneasLeanBuilt = aeneas-lean-backend;
        };

        verification = pkgs.symlinkJoin {
          name = "lean-verification";
          paths = [
            lean-translation
            proofs
          ];
        };

        default = package;
      };
    };
}
