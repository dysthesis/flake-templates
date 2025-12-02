{
  stdenvNoCC,
  pkgs,
  lib,
  lean-translation,
  aeneasLib,
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

    # Stage the generated Lean code and Aeneas library into .lake/build/lib
    mkdir -p .lake/build/lib/lean

    # Copy generated Lean definitions from lean-translation
    if [ -d "${lean-translation}/lib/lean" ]; then
      cp -r "${lean-translation}/lib/lean/." .lake/build/lib/lean/
    else
      echo "Error: lean-translation output not found at ${lean-translation}/lib/lean" >&2
      exit 1
    fi

    # Copy Aeneas standard library
    if [ -d "${aeneasLib}/lib/lean" ]; then
      cp -r "${aeneasLib}/lib/lean/." .lake/build/lib/lean/
    else
      echo "Error: Aeneas library not found at ${aeneasLib}/lib/lean" >&2
      exit 1
    fi

    # Set LEAN_PATH to include both translation output and Aeneas library
    export LEAN_PATH="${lean-translation}/lib/lean:${aeneasLib}/lib/lean"
    export LEAN_SRC_PATH="${lean-translation}/lib/lean:${aeneasLib}/lib/lean"

    # Build the Lean proofs project
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
Aeneas Library: ${aeneasLib}
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
