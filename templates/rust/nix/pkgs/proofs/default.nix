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

    # Copy the pre-built Aeneas library (with compiled .olean files) into .lake/build/lib/lean
    if [ -d "${aeneasLeanBuilt}/lib/lean" ]; then
      echo "Copying pre-built Aeneas library with compiled modules..."

      # Copy Aeneas directories and top-level files to where Lean expects them
      for item in Aeneas AeneasMeta Aeneas.lean AeneasMeta.lean AeneasExtract.lean; do
        if [ -e "${aeneasLeanBuilt}/lib/lean/$item" ]; then
          cp -r "${aeneasLeanBuilt}/lib/lean/$item" .lake/build/lib/lean/
        fi
      done

      # Copy Lake packages if they exist
      if [ -d "${aeneasLeanBuilt}/lib/lean/.lake-packages" ]; then
        mkdir -p .lake
        cp -r "${aeneasLeanBuilt}/lib/lean/.lake-packages" .lake/packages
      fi
    else
      echo "Error: Pre-built Aeneas library not found at ${aeneasLeanBuilt}/lib/lean" >&2
      exit 1
    fi

    # Copy generated Lean definitions from lean-translation into proper module hierarchy
    if [ -d "${lean-translation}/lib/lean" ]; then
      # Create Libtemplate module directory for the generated files
      mkdir -p .lake/build/lib/lean/Libtemplate

      # Copy all .lean files (excluding symlinks like the Aeneas directory) into Libtemplate/
      find "${lean-translation}/lib/lean" -maxdepth 1 -type f -name '*.lean' -exec cp {} .lake/build/lib/lean/Libtemplate/ \;

      # Create a top-level Libtemplate.lean that imports all generated modules
      cat > .lake/build/lib/lean/Libtemplate.lean <<'EOF'
-- Re-export all modules from the Libtemplate namespace
import Libtemplate.Types
import Libtemplate.Funs
EOF
    else
      echo "Error: lean-translation output not found at ${lean-translation}/lib/lean" >&2
      exit 1
    fi

    # Set LEAN_PATH to use the staged libraries
    export LEAN_PATH=.lake/build/lib/lean
    export LEAN_SRC_PATH=.lake/build/lib/lean

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
