{
  stdenvNoCC,
  pkgs,
  lib,
  lean-translation,
  aeneasLeanBuilt,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "lean-proofs";
  version = "0.1.0";

  src = builtins.path {
    path = ../../..;
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

    # Create .lake/build/lib/lean directory structure
    mkdir -p .lake/build/lib/lean

    # Copy the pre-built Aeneas library (compiled .olean files and metadata)
    if [ -d "${aeneasLeanBuilt}/lib/lean" ]; then
      echo "Copying pre-built Aeneas library with compiled modules..."

      cp -r "${aeneasLeanBuilt}/lib/lean"/. .lake/build/lib/lean/

      # Copy Lake packages if they exist
      if [ -d "${aeneasLeanBuilt}/lib/lean/.lake-packages" ]; then
        mkdir -p .lake
        cp -r "${aeneasLeanBuilt}/lib/lean/.lake-packages" .lake/packages
      fi
    else
      echo "Error: Pre-built Aeneas library not found at ${aeneasLeanBuilt}/lib/lean" >&2
      exit 1
    fi

    # Stage generated Lean definitions from the translation output (expected under lib/lean)
    if [ -d "${lean-translation}/lib/lean" ]; then
      mkdir -p .lake/build/lib/lean
      cp -r "${lean-translation}/lib/lean"/. .lake/build/lib/lean/
    else
      echo "Error: lean-translation output not found at ${lean-translation}/lib/lean" >&2
      exit 1
    fi

    # Bring in the Lean dependencies Aeneas was built against (mathlib, aesop, batteries, proofwidgets, ...)
    shopt -s nullglob
    staged_mathlib=false
    for dep in /nix/store/*-{mathlib,aesop,batteries,Cli,importGraph,LeanSearchClient,plausible,Qq,proofwidgets}; do
      if [ -d "$dep/lib/lean" ]; then
        cp -r "$dep/lib/lean"/. .lake/build/lib/lean/
      fi

      if [ -d "$dep/.lake/build/lib/lean" ]; then
        cp -r "$dep/.lake/build/lib/lean"/. .lake/build/lib/lean/
      fi

      if [ -f "$dep/.lake/build/lib/lean/Mathlib.olean" ] || [ -f "$dep/lib/lean/Mathlib.olean" ]; then
        staged_mathlib=true
      fi
    done

    if [ "$staged_mathlib" = false ]; then
      echo "Error: Unable to locate mathlib dependency in the Aeneas closure" >&2
      exit 1
    fi

    # Ensure translation files are writable for compilation
    chmod -R u+w .lake/build/lib/lean/Libtemplate

    # Set LEAN_PATH to use the staged libraries
    export LEAN_PATH=.lake/build/lib/lean
    export LEAN_SRC_PATH=.lake/build/lib/lean

    # Precompile the generated translation so downstream imports find .olean files
    lean --root=$LEAN_SRC_PATH -o .lake/build/lib/lean/Libtemplate/Types.olean .lake/build/lib/lean/Libtemplate/Types.lean
    lean --root=$LEAN_SRC_PATH -o .lake/build/lib/lean/Libtemplate/Funs.olean .lake/build/lib/lean/Libtemplate/Funs.lean
    lean --root=$LEAN_SRC_PATH -o .lake/build/lib/lean/Libtemplate.olean .lake/build/lib/lean/Libtemplate.lean

    # Build the Lean proofs project
    # Lean will now find the precompiled Aeneas modules and compile Libtemplate and Proofs
    echo "Building proofs..."
    lake build
  '';

  installPhase = ''
        set -eux

        mkdir -p "$out/lib/lean"

        # Install built Lean libraries
        if [ -d .lake/build/lib/lean ]; then
          cp -r .lake/build/lib/lean/* "$out/lib/lean/"
        fi

        # Create a metadata file documenting what was verified
        mkdir -p "$out/nix-support"
        cat > "$out/nix-support/verification-info" <<EOF
    Lean Proofs Build
    =================
    This derivation contains Lean proofs that verify properties of Rust code
    translated to Lean via Aeneas/Charon.

    Translation: ${lean-translation}
    Aeneas Library: ${aeneasLeanBuilt}
    Proofs Source: ../../proofs

    The build success indicates that:
    1. Generated Lean code from Rust type-checks correctly
    2. All theorems in the proofs/ directory hold against the generated code
    3. The Rust implementation satisfies its formal specification
    EOF
  '';

  meta = {
    description = "Lean proofs for the Rust template";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
