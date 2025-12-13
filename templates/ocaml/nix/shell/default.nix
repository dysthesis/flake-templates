{
  perSystem =
    {
      pkgs,
      scope',
      localPackagesQuery,
      devPackagesQuery,
      ...
    }:
    let
      # Extract package sets from the scope
      devPackages = builtins.attrValues (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');

      localPackages =
        if localPackagesQuery != { } then
          pkgs.lib.getAttrs (builtins.attrNames localPackagesQuery) scope'
        else
          { };
    in
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.attrValues localPackages;
        buildInputs = devPackages;
      };
    };
}
