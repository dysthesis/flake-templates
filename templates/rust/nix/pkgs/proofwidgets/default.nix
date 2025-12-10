{
  pkgs,
  stdenv,
  fetchFromGitHub,
  nodejs,
  runCommand,
  lake2nix,
  ...
}: let
  # Fetch ProofWidgets source (version from Aeneas manifest)
  proofWidgetsSrc = fetchFromGitHub {
    owner = "leanprover-community";
    repo = "ProofWidgets4";
    rev = "45777338ffb69576c945dfe9466665b8023a8b8c"; # v0.0.80+lean-v4.25.2
    hash = "sha256-X5FerfiWggLZ+BEZcdXFZ12STHsaI7bD1qpWCwwv01c=";
  };

  # Vendor npm dependencies using fetchNpmDeps
  npmDeps = pkgs.fetchNpmDeps {
    src = "${proofWidgetsSrc}/widget";
    hash = "sha256-CzBRrreOSytquZ/xFHPlY8r+lz5Bg9Zk9ienRhc8SiY=";
  };

  # Pre-build widget JavaScript files using vendored npm
  widgetBuilt = stdenv.mkDerivation {
    pname = "proofwidgets-widget-built";
    version = "0.0.80";

    src = "${proofWidgetsSrc}/widget";

    nativeBuildInputs = [nodejs pkgs.npmHooks.npmConfigHook];
    inherit npmDeps;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR/npm-home
      mkdir -p "$HOME"

      # npmConfigHook already installed deps; just ensure bin wrappers are patched
      patchShebangs node_modules

      # Build the widget files (production build)
      npm run build

      runHook postBuild
    '';

    installPhase = ''
      mkdir -p $out
      # Copy built widget files
      cp -r dist $out/
    '';

    dontFixup = true;
  };

  # Source with patched lakefile and JS paths
  patchedSrc = stdenv.mkDerivation {
    name = "proofwidgets-source-patched";
    src = proofWidgetsSrc;

    buildPhase = ''
      runHook preBuild

      # Patch lakefile to install pre-built widget files instead of running npm
      substituteInPlace lakefile.lean \
        --replace-fail \
          'pkg.runNpmCommand #["clean-install"]' \
          'IO.FS.createDirAll (pkg.buildDir / "js")' \
        --replace-fail \
          'pkg.runNpmCommand #["run", if isDev then "build-dev" else "build"]' \
          'IO.FS.writeFile (pkg.buildDir / "js" / ".widgets-installed") "pre-built"' \
        --replace-fail \
          $'if let some msg := get_config? errorOnBuild then\n        error msg' \
          'pure () -- Nix: errorOnBuild disabled (using Nix-provided widget files)'

      # Patch all .lean files to reference JS files from share/js instead of .lake/build/js
      # This is necessary because lake2nix mounts tmpfs over .lake/build during dependent builds
      echo "Patching .lean files to use share/js instead of .lake/build/js..."
      find . -name "*.lean" -type f -print0 | while IFS= read -r -d "" file; do
        echo "  Patching: $file"
        sed -i 's|"\.\." / "\.\." / "\.\." / "\.lake" / "build" / "js"|".." / ".." / ".." / "share" / "js"|g' "$file"
        sed -i 's|"\.\." / "\.\." / "\.lake" / "build" / "js"|".." / ".." / "share" / "js"|g' "$file"
        sed -i 's|"\.\." /  "\.\." / "\.lake" / "build" / "js"|".." / ".." / "share" / "js"|g' "$file"
      done
      echo "Patching complete."

      runHook postBuild
    '';

    installPhase = ''
      cp -r . $out
    '';

    dontFixup = true;
  };
in
  # Build ProofWidgets using lake2nix with pre-built widgets
  lake2nix.mkLakeDerivation {
    name = "proofwidgets";
    src = patchedSrc;

    # Install pre-built JavaScript files before Lake build
    # Files go to both share/js (for dependent packages) and .lake/build/js (for this build)
    preBuild = ''
      echo "Installing pre-built ProofWidgets JavaScript files..."
      mkdir -p share/js
      mkdir -p .lake/build/js
      cp -r ${widgetBuilt}/dist/* share/js/
      cp -r ${widgetBuilt}/dist/* .lake/build/js/
      chmod -R +w share/js .lake/build/js
    '';

    # The JS files in share/js are accessible to dependent packages because
    # share/ is not covered by tmpfs mounts in lake2nix's bubblewrap sandbox
    nativeBuildInputs = [nodejs];
  }
