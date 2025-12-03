# Modified version of
# https://github.com/lenianiva/lean4-nix/blob/main/lib/packages.nix
{
  pkgs,
  lib,
  stdenv,
  lean,
  extraBuildInputs ? [],
}: let
  capitalise = s: let
    first = lib.toUpper (builtins.substring 0 1 s);
    rest = builtins.substring 1 (-1) s;
  in
    first + rest;
  importLakeManifest = manifestFile: let
    manifest = lib.importJSON manifestFile;
  in
    lib.warnIf (manifest.version != "1.1.0") ("Unknown version: " + builtins.toString manifest.version) manifest;
  # A wrapper around `mkDerivation` which sets up the lake manifest
  mkLakeDerivation = args @ {
    src,
    deps ? {},
    ...
  }: let
    manifest = importLakeManifest "${src}/lake-manifest.json";
    # create a surrogate manifest
    replaceManifest =
      pkgs.writers.writeJSON "lake-manifest.json"
      (
        lib.setAttr manifest "packages" (builtins.map ({
            name,
            inherited ? false,
            ...
          }: {
            inherit name inherited;
            type = "path";
            dir = deps.${name};
          })
          manifest.packages)
      );
  in
    stdenv.mkDerivation (
      {
        inherit src;

        unpackPhase = ''
          runHook preUnpack

          # Copy the repo out of /nix/store into the writable build dir
          echo "Copying source from ${src}"
          cp -R "${src}"/. .
          chmod -R u+w .

          # Verify files were copied
          echo "Contents of build directory:"
          ls -la

          runHook postUnpack
        '';

        buildInputs = extraBuildInputs ++ [lean.lean-all];

        configurePhase = ''
          runHook preConfig

          # NOTE: We do this rather than use the surrogate manifest in order to
          # allow the build process write access.
          mkdir -p .lake/build/lib

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (depName: depPath: ''
              echo "Staging dependency: ${depName} from ${depPath}"
              if [ -d "${depPath}/lib/lean" ]; then
                cp -r "${depPath}/lib/lean" .lake/build/lib/
              fi
            '')
            deps)}

          # Verify lake configuration
          echo "Lake configuration ready"
          ls -la lakefile.* || echo "Warning: No lakefile found"
          echo "Staged dependencies in .lake/build/lib:"
          ls -la .lake/build/lib/ || true
          ls -la .lake/build/lib/* || true

          runHook postConfig
        '';

        buildPhase = ''
          runHook preBuild

          lake build

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p "$out"

          # Install only the build artifacts as a pre-built library
          # This prevents Lake from trying to rebuild dependencies in the Nix store
          if [ -d .lake/build/lib ]; then
            mkdir -p "$out/lib"
            cp -r .lake/build/lib/lean "$out/lib/" || true
          fi

          # Also copy bin if it exists (for executables)
          if [ -d .lake/build/bin ]; then
            cp -r .lake/build/bin "$out/" || true
          fi

          # Install IR and object files if they exist
          if [ -d .lake/build/ir ]; then
            mkdir -p "$out/ir"
            cp -r .lake/build/ir/* "$out/ir/" || true
          fi

          runHook postInstall
        '';
      }
      // (builtins.removeAttrs args ["deps" "src"])
    );
  # Builds a Lean package by reading the manifest file.
  mkPackage = args @ {
    # Path to the source
    src,
    # Path to the `lake-manifest.json` file
    manifestFile ? "${src}/lake-manifest.json",
    # Root module
    roots ? null,
    # Static library dependencies
    staticLibDeps ? [],
    ...
  }: let
    manifest = importLakeManifest manifestFile;

    roots =
      args.roots or [(capitalise manifest.name)];

    depSources = builtins.listToAttrs (builtins.map (info: {
        inherit (info) name;
        value = builtins.fetchGit {
          inherit (info) url rev;
          shallow = true;
        };
      })
      manifest.packages);
    # construct dependency name map
    flatDeps =
      lib.mapAttrs (
        _name: src: let
          manifest = importLakeManifest "${src}/lake-manifest.json";
          deps = builtins.map ({name, ...}: name) manifest.packages;
        in
          deps
      )
      depSources;

    # Build all dependencies
    manifestDeps = builtins.listToAttrs (builtins.map (info: {
        inherit (info) name;
        value = mkLakeDerivation {
          inherit (info) name url;
          src = depSources.${info.name};
          deps = builtins.listToAttrs (builtins.map (name: {
              inherit name;
              value = manifestDeps.${name};
            })
            flatDeps.${info.name});
        };
      })
      manifest.packages);
  in
    mkLakeDerivation {
      inherit src;
      inherit (manifest) name;
      deps = manifestDeps;
      nativeBuildInputs = staticLibDeps;
      buildPhase =
        args.buildPhase
        or ''
          lake build #${builtins.concatStringsSep " " roots}
        '';
      installPhase =
        args.installPhase
        or ''
          mkdir $out
          if [ -d .lake/build/bin ]; then
            mv .lake/build/bin $out/
          fi
          if [ -d .lake/build/lib ]; then
            mv .lake/build/lib $out/
          fi
        '';
    };
in {
  inherit mkLakeDerivation mkPackage;
}
