{
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
    ...
  }: let
    inherit (pkgs) callPackage;
  in rec {
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

      lean-translation = callPackage ./lean-translation {
        inherit lib charonToolchain craneLib;
        inherit (inputs'.aeneas.packages) aeneas charon;
        src = ../../.;
      };

      lean-proofs = pkgs.stdenvNoCC.mkDerivation {
        pname = "lean-proofs";
        version = "0.1.0";

        src = builtins.path {
          path = ../../.;
          name = "rust-template-src";
        };

        nativeBuildInputs = [
          pkgs.lean4
        ];

        dontConfigure = true;

        buildPhase = ''
          set -eux

          cp -r "$src" crate
          chmod -R u+w crate
          cd crate/proofs

          mkdir -p .lake/build/lib/lean
          cp -r ${lean-translation}/lib/lean/. .lake/build/lib/lean/
          cp -r ${aeneasLib}/lib/lean/. .lake/build/lib/lean/

          export LEAN_PATH=${lean-translation}/lib/lean:${aeneasLib}/lib/lean
          export LEAN_SRC_PATH=${lean-translation}/lib/lean:${aeneasLib}/lib/lean

          # Pre-build the Aeneas library so imports resolve under Lake's lean path
          LEAN_PATH=.lake/build/lib/lean ${pkgs.lean4}/bin/lean .lake/build/lib/lean/Aeneas.lean

          lake build
        '';

        installPhase = ''
          set -eux

          mkdir -p "$out/lib/lean"
          cp -r .lake/build/lib/lean/* "$out/lib/lean/"
        '';

        meta = {
          description = "Lean proofs for the Rust template";
          license = lib.licenses.asl20;
          platforms = lib.platforms.unix;
        };
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
