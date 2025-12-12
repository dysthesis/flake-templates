{
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    inherit (self'.packages) mathlib;

    mkLeanRegistry = import ./mkLeanRegistry.nix pkgs;

    leanLibraries = mkLeanRegistry {
      staticLibs = [
        {
          name = "mathlib";
          path = "${mathlib}/lib/lean";
        }
      ];
    };
  in {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Nix
        nixd
        statix
        deadnix
        alejandra

        lean4
      ];

      LEAN_SRC_PATH =
        builtins.trace "${leanLibraries.staticPath}"
        leanLibraries.staticPath;
      LEAN_PATH = leanLibraries.staticPath;
      LEAN_LIBRARY_REGISTRY = leanLibraries.manifest;
    };
  };
}
