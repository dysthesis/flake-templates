{
  perSystem =
    {
      pkgs,
      scope',
      localPackagesQuery,
      ...
    }:
    let
      # Extract local packages from the scope
      localPackages =
        if localPackagesQuery != { } then
          pkgs.lib.getAttrs (builtins.attrNames localPackagesQuery) scope'
        else
          { };
    in
    {
      # Expose local packages built from this workspace
      packages = localPackages;

      # Expose the full opam scope for advanced users
      legacyPackages = scope';

      # To define a default package when the project has one:
      # packages = localPackages // lib.optionalAttrs (localPackages ? <pkg-name>) {
      #   default = localPackages.<pkg-name>;
      # };
    };
}
