top@{
  inputs,
  ...
}: {
  perSystem = {
    craneLib,
    pkgs,
    src,
    commonArgs,
    cargoArtifacts,
    lib,
    inputs',
    charonToolchain,
    aeneasLib,
    aeneasSrc,
    ...
  }: let
    inherit (pkgs) callPackage;
    lake2nix = pkgs.callPackage inputs.lean4-nix.lake { lean = pkgs.lean; };
  in rec {
    _module.args.aeneasLeanBuilt = packages.aeneas-lean-built;
    _module.args.lean-translation = packages.lean-translation;
    _module.args.lean-proofs = packages.lean-proofs;
    _module.args.lean-verification = packages.lean-verification;
    packages = rec {
      package = callPackage ./package {
        inherit
          craneLib
          pkgs
          commonArgs
          cargoArtifacts
          ;
      };

      aeneas-lean-built = callPackage ./aeneas-lean-built {
        inherit lib aeneasSrc;
      };

      lean-translation = callPackage ./lean-translation {
        inherit lib charonToolchain craneLib aeneasLib;
        inherit (inputs'.aeneas.packages) aeneas charon;
        src = ../../.;
      };

      lean-proofs = callPackage ./proofs {
        inherit lib lean-translation;
        aeneasLeanBuilt = aeneas-lean-built;
      };

      lean-verification = pkgs.buildEnv {
        name = "lean-verification";
        paths = [
          lean-translation
          lean-proofs
          aeneasLib
        ];
        pathsToLink = [ "/lib/lean" ];
      };

      default = package;
    };
  };
}
