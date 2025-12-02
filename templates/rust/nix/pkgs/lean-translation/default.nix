{
  stdenvNoCC,
  # Charon's Rust toolchain
  charonToolchain,
  aeneas,
  charon,
  src ? ../../..,
  lib,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "lean-translation";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [ charonToolchain ];
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

    export PATH=${charonToolchain}/bin:$PATH
    export RUSTUP_HOME=$PWD/.rustup
    export CARGO_HOME=$PWD/.cargo

    ${lib.getExe charon} cargo --preset=aeneas

    llbc_files=$(ls *.llbc)
    if [ "$(printf '%s\n' $llbc_files | wc -l)" -ne 1 ]; then
      echo "Expected exactly one .llbc file, found: $llbc_files" >&2
      exit 1
    fi
    llbc_file="$llbc_files"

    ${lib.getExe aeneas} -backend lean -split-files "$llbc_file"
  '';

  installPhase = ''
    set -eux
    mkdir -p "$out"

    find . -name '*.lean' -print0 \
      | xargs -0 -I '{}' sh -c 'mkdir -p "$out/$(dirname "{}")"; cp "{}" "$out/{}"'
  '';

  doCheck = false;
}
