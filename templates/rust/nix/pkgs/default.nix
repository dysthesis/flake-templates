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

      proofwidgets = callPackage ./proofwidgets {inherit lake2nix;};

      aeneas-lean-backend = callPackage ./aeneas-lean-backend {
        inherit lake2nix proofwidgets;
      };

      lean-translation = callPackage ./lean-translation {
        inherit lib charonToolchain craneLib aeneas-lean-backend lake2nix;
        inherit (inputs'.aeneas.packages) aeneas charon;
        src = ../../.;
      };

      # Build the Lean proofs against the generated translation and the
      # Aeneas Lean backend.
      lean-proofs = callPackage ./proofs {
        inherit pkgs lib lean-translation;
        aeneasLeanBuilt = aeneas-lean-backend;
      };

      # Combined verification output: everything needed to import the
      # translated library and the proofs as a single Lean library tree.
      lean-verification = pkgs.symlinkJoin {
        name = "lean-verification";
        paths = [
          lean-translation
          lean-proofs
        ];
      };

      default = package;
    };
  };
}
