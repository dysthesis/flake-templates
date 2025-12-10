{
  stdenvNoCC,
  writers,
  craneLib,
  # lake2nix,
  # Charon's Rust toolchain
  charonToolchain,
  aeneas,
  charon,
  aeneas-lean-backend,
  src ? ../../..,
  lib,
  ...
}: let
  cargoVendorDir = craneLib.vendorCargoDeps {
    inherit src;
  };
  dependencies = [
    {
      name = "aeneas";
      path = aeneas-lean-backend;
    }
  ];

  lakefile = writers.writeTOML "lakefile.toml" {
    require = dependencies;
  };

  translated = stdenvNoCC.mkDerivation {
    pname = "lean-translation";
    version = "0.1.0";

    inherit src;

    nativeBuildInputs = [charonToolchain];
    buildInputs = [
      charon
      aeneas
    ];

    dontConfigure = true;

    buildPhase = ''
      set -eux

      cp -r "$src" crate
      chmod -R u+w crate
      cd crate

      crate_manifest=$(find . -name Cargo.toml -print | head -n1 || true)

      if [ -z "$crate_manifest" ]; then
        echo "No Cargo.toml found under $PWD – this source is not a Rust crate (or crate is in an unexpected place)." >&2
        exit 1
      fi

      crate_dir=$(dirname "$crate_manifest")
      cd "$crate_dir"

      echo "Using crate root: $PWD (found $crate_manifest)"

      mkdir -p .cargo
      cat ${cargoVendorDir}/config.toml > .cargo/config.toml
      cat >> .cargo/config.toml <<'EOF'
      [net]
      offline = true
      EOF

      export PATH=${charonToolchain}/bin:$PATH
      export RUSTUP_HOME=$PWD/.rustup
      export CARGO_HOME=$PWD/.cargo

      ${lib.getExe charon} cargo --preset=aeneas

      shopt -s nullglob
      llbc_files=(*.llbc)
      if [ "''${#llbc_files[@]}" -eq 0 ]; then
        echo "No .llbc files produced by charon; expected at least one." >&2
        exit 1
      fi

      lib_llbc_files=(lib*.llbc)
      if [ "''${#lib_llbc_files[@]}" -gt 0 ]; then
        llbc_files=("''${lib_llbc_files[@]}")
      fi

      for llbc_file in "''${llbc_files[@]}"; do
        echo "Translating $llbc_file to Lean"
        ${lib.getExe aeneas} -backend lean -split-files "$llbc_file"
      done
    '';

    installPhase = ''
      set -eux
      mkdir -pv $out

      find . -name '*.lean' ! -path '*/proofs/*' -print0 \
        | xargs -0 -I '{}' install -Dm644 '{}' "$out/{}"

      cp ${lakefile} $out/lakefile.toml
    '';

    doCheck = false;
  };
in
  translated
