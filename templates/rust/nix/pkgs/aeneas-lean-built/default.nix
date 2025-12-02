{
  stdenvNoCC,
  pkgs,
  lib,
  aeneasSrc,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "aeneas-lean-built";
  version = "0.1.0";

  src = aeneasSrc;

  nativeBuildInputs = [
    pkgs.lean4
    pkgs.git
    pkgs.cacert
  ];

  # Make this a fixed-output derivation to allow network access for fetching mathlib
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = lib.fakeHash;  # Will be replaced with actual hash after first build

  impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
    "GIT_PROXY_COMMAND" "SOCKS_SERVER"
  ];

  buildPhase = ''
    set -eux

    cd backends/lean

    # Allow Lake to fetch dependencies
    export HOME=$TMPDIR
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

    # Build the Aeneas Lean library
    # This will fetch mathlib and build everything
    lake build Aeneas AeneasMeta
  '';

  installPhase = ''
    set -eux

    mkdir -p $out/lib/lean

    # Copy source files (without lakefile to avoid downstream issues)
    cp -r Aeneas $out/lib/lean/
    cp -r AeneasMeta $out/lib/lean/
    cp Aeneas.lean $out/lib/lean/
    cp AeneasMeta.lean $out/lib/lean/
    cp AeneasExtract.lean $out/lib/lean/
    cp lean-toolchain $out/lib/lean/

    # Copy compiled .olean and related files from build output
    if [ -d .lake/build/lib ]; then
      # Merge compiled files with source files
      find .lake/build/lib -type f \( -name "*.olean" -o -name "*.ilean" -o -name "*.trace" -o -name "*.hash" \) | while read file; do
        rel_path="''${file#.lake/build/lib/}"
        target_dir="$out/lib/lean/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/"
      done
    fi

    # Copy Lake packages (mathlib, etc.) that were built
    if [ -d .lake/packages ]; then
      cp -r .lake/packages $out/lib/lean/.lake-packages
    fi
  '';

  meta = {
    description = "Pre-built Aeneas Lean library with mathlib dependencies";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
