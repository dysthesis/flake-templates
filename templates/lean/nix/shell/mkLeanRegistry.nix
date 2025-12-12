pkgs: {
  staticLibs,
  runtimeLibs ? [],
}: let
  inherit (pkgs) lib;

  mkPath = paths: lib.concatStringsSep ":" (lib.unique paths);

  # Derive the store root for a Lean path (usually /lib/lean or /.lake/build/lib/lean).
  basePath = p: let
    pStr = toString p;
  in
    if lib.hasSuffix "/lib/lean" pStr
    then builtins.dirOf (builtins.dirOf pStr)
    else if lib.hasSuffix "/.lake/build/lib/lean" pStr
    then builtins.dirOf (builtins.dirOf (builtins.dirOf pStr))
    else pStr;

  # Lean search paths for a store-backed library; we only include paths that already exist.
  leanDirsStatic = base: let
    candidates = [
      "${base}/lib/lean"
      "${base}/.lake/build/lib/lean"
    ];
  in
    lib.filter builtins.pathExists candidates;

  # Lean search paths for worktree/runtime libraries; keep placeholders (no pathExists).
  leanDirsRuntime = base: let
    p = toString base;
    candidates = [
      p
      "${p}/lib/lean"
      "${p}/.lake/build/lib/lean"
    ];
  in
    lib.unique candidates;

  # Collect the full Nix store closure of the static libraries so dependencies (mathlib, proofwidgets, batteries, ...)
  # are pulled into the Lean path as well.
  closurePaths = let
    roots = map (lib: basePath lib.path) staticLibs;
    closureInfo = pkgs.closureInfo {rootPaths = roots;};
    contents = builtins.readFile "${closureInfo}/store-paths";
  in
    lib.filter (p: p != "") (lib.splitString "\n" (lib.removeSuffix "\n" contents));

  # Parse any lake-manifest.json files that appear in the closure to recover package names for the registry.
  manifestPackages = lib.concatMap (
    manifestPath: let
      manifestJson =
        builtins.unsafeDiscardStringContext (builtins.readFile manifestPath);
      parsed = builtins.fromJSON manifestJson;
    in
      lib.optionals (parsed ? packages)
      (map (pkg: {
          name = pkg.name;
          path = pkg.dir;
        })
        parsed.packages)
  ) (lib.filter (p: lib.hasSuffix "lake-manifest.json" p) closurePaths);

  # Entries explicitly requested by the caller.
  staticEntries =
    map (lib: {
      inherit (lib) name;
      path = basePath lib.path;
    })
    staticLibs;
  runtimeEntries =
    map (lib: {
      inherit
        (lib)
        name
        path
        ;
    })
    runtimeLibs;

  addIfMissing = acc: entry:
    if acc ? "${entry.name}"
    then acc
    else acc // {"${entry.name}" = entry.path;};
  addOrReplace = acc: entry: acc // {"${entry.name}" = entry.path;};

  namesAfterStatics = lib.foldl' addIfMissing {} staticEntries;
  namesAfterDeps = lib.foldl' addIfMissing namesAfterStatics manifestPackages;
  finalNames = lib.foldl' addOrReplace namesAfterDeps runtimeEntries;

  registryEntries =
    lib.mapAttrsToList (n: p: {
      name = n;
      path = p;
    })
    finalNames;

  staticLeanPaths = lib.unique (lib.concatMap leanDirsStatic closurePaths);
  runtimeLeanPaths = lib.unique (lib.concatMap (entry: leanDirsRuntime entry.path) runtimeEntries);

  toLine = lib: "${lib.name}: ${lib.path}";
in {
  staticPath = mkPath staticLeanPaths;
  runtimePathTemplate = mkPath runtimeLeanPaths;
  manifest = pkgs.writeText "lean-library-registry" (
    lib.concatStringsSep "\n" (map toLine registryEntries)
  );
}
