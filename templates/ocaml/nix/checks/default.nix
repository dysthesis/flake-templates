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
      # Local packages serve as basic build checks
      checks = localPackages;

      # Future expansion: format checks, lint checks, etc.
      # checks = localPackages // {
      #   format = pkgs.runCommand "check-format" { ... } ''...'';
      # };
    };
}
