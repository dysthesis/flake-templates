{
  perSystem = {
    pkgs,
    craneLib,
    inputs',
    self',
    ...
  }: let
    valeConfigured = pkgs.callPackage ./vale {};

    # Packages from this flake
    leanTranslation = self'.packages.lean-translation;
    aeneasLib = self'.packages.aeneas-lean-backend;
    inherit (self'.packages) mathlib;

    # Small helper to build Lean search paths and keep a manifest of registered libraries.
    mkLeanRegistry = {
      staticLibs,
      runtimeLibs ? [],
    }: let
      mkPath = paths: pkgs.lib.concatStringsSep ":" (pkgs.lib.unique paths);
      toLine = lib: "${lib.name}: ${lib.path}";
    in {
      staticPath = mkPath (map (lib: lib.path) staticLibs);
      runtimePathTemplate = mkPath (map (lib: lib.path) runtimeLibs);
      manifest = pkgs.writeText "lean-library-registry" (
        pkgs.lib.concatStringsSep "\n" (map toLine (staticLibs ++ runtimeLibs))
      );
    };

    leanLibraries = mkLeanRegistry {
      staticLibs = [
        # Prebuilt store paths (always available)
        {
          name = "aeneas";
          path = "${aeneasLib}/lib/lean";
        }
        {
          name = "libtemplate";
          path = "${leanTranslation}/lib/lean";
        }
        {
          name = "mathlib";
          path = "${mathlib}/lib/lean";
        }
      ];

      runtimeLibs = [
        # Worktree-dependent paths (resolved in shellHook)
        {
          name = "proofs-src";
          path = "$LEAN_PROJECT_ROOT/proofs";
        }
        {
          name = "proofs-lake-build";
          path = "$LEAN_PROJECT_ROOT/proofs/.lake/build/lib/lean";
        }
        {
          name = "proofs-lake-packages";
          path = "$LEAN_PROJECT_ROOT/proofs/.lake/packages";
        }
      ];
    };
  in {
    devShells.default = craneLib.devShell {
      packages = with pkgs; [
        # Nix
        nixd
        statix
        deadnix
        alejandra

        # Rust
        cargo-audit
        cargo-expand
        cargo-nextest
        rust-analyzer
        cargo-wizard
        bacon

        # Prose
        valeConfigured

        # Theorem proving
        inputs'.aeneas.packages.aeneas
        lean4
      ];

      LEAN_SRC_PATH =
        builtins.trace "${leanLibraries.staticPath}"
        leanLibraries.staticPath;
      LEAN_PATH = leanLibraries.staticPath;
      LEAN_LIBRARY_REGISTRY = leanLibraries.manifest;
    };
  };
}
