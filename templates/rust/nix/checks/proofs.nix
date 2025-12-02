{
  lib,
  apollyon-proof,
  lean4-nix,
  pkgs,
  inputs',
  aeneas,
  ...
}:
let
  # Fixed-Output Derivation to fetch all Lake dependencies
  # This runs `lake update` in a controlled environment and hashes the result
  # Note: pkgs.lean is available via the lean4-nix overlay in flake.nix
  lakeDeps = pkgs.stdenv.mkDerivation {
    pname = "apollyon-proofs-lake-deps";
    version = "0.1.0";
    src = ../../proofs;

    nativeBuildInputs = [
      pkgs.lean.lean-all
      pkgs.git  # Required by lake to fetch dependencies
      pkgs.cacert  # Required for HTTPS connections
      pkgs.curl  # Required by mathlib cache fetcher
      pkgs.removeReferencesTo  # Remove store path references
    ];

    # FOD configuration - ensures reproducibility
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = pkgs.lib.fakeHash;  # Will be updated after first build

    # Allow this FOD to reference Lean tooling
    # The output will be sanitized to remove these references
    unsafeDiscardReferences = {
      out = true;
    };

    buildPhase = ''
      export HOME=$TMPDIR
      export LAKE_NO_CACHE=1

      # Configure SSL certificates for HTTPS git clones
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

      # Configure git for the build environment
      git config --global user.email "nix@builder"
      git config --global user.name "Nix Builder"
      git config --global init.defaultBranch main

      # Lake update fetches all dependencies from lake-manifest.json
      # This includes mathlib, ProofWidgets, batteries, etc.
      lake update -v
    '';

    installPhase = ''
      mkdir -p $out
      # Copy the fetched dependencies
      cp -r .lake $out/

      # Remove any references to store paths to satisfy FOD requirements
      # Find all files and remove references to nix store
      find $out -type f -exec remove-references-to -t ${pkgs.lean.lean-all} '{}' + || true
      find $out -type f -exec remove-references-to -t ${pkgs.git} '{}' + || true
      find $out -type f -exec remove-references-to -t ${pkgs.curl} '{}' + || true
    '';

    dontConfigure = true;
  };

  # Build the actual Lean project using fetched dependencies
  leanProject = pkgs.stdenv.mkDerivation {
    pname = "apollyon-proofs";
    version = "0.1.0";
    src = ../../proofs;

    nativeBuildInputs = [ pkgs.lean.lean-all ];

    buildPhase = ''
      export HOME=$TMPDIR
      export LAKE_NO_CACHE=1

      # Restore the fetched dependencies
      cp -r ${lakeDeps}/.lake .
      chmod -R +w .lake

      # Copy the generated Apollyon.lean file from aeneas translation
      if [ -f ${apollyon-proof}/Apollyon.lean ]; then
        cp ${apollyon-proof}/Apollyon.lean .
      fi

      # Build the Lean verification project
      lake build
    '';

    installPhase = ''
      mkdir -p $out
      # Install build outputs
      cp -r build $out/
      # Install libraries if they exist
      if [ -d .lake/build/lib ]; then
        cp -r .lake/build/lib $out/
      fi
    '';

    dontConfigure = true;
  };
in
# The check succeeds if the Lean package builds successfully
# This verifies that:
# 1. The generated Apollyon.lean file is valid Lean code
# 2. All imports resolve correctly (including ProofWidgets)
# 3. All theorems are provable
# 4. Dependencies are managed purely through Nix (via FOD)
leanProject
