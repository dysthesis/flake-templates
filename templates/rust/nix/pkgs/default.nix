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
    lake2nix = pkgs.callPackage inputs.lean4-nix.lake { lean = pkgs.lean4; };
  in rec {
    _module.args.lean-translation = packages.lean-translation;
    _module.args.lean-proofs = packages.lean-proofs;
    _module.args.lean-verification = packages.lean-verification;
    _module.args.aeneas-lean = packages.aeneas-lean;
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
        inherit lib charonToolchain craneLib aeneasLib;
        inherit (inputs'.aeneas.packages) aeneas charon;
        src = ../../.;
      };

      aeneas-lean = lake2nix.mkPackage {
        src = aeneasSrc + "/backends/lean";
        roots = [ "Aeneas" ];
      };

      lean-proofs = callPackage ./proofs {
        inherit lib lean-translation aeneasLib;
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
