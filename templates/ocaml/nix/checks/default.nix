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
      checks = localPackages // {
        # Format verification (Nix + OCaml)
        format =
          let
            src = pkgs.lib.cleanSourceWith {
              src = ../..;
              filter =
                path: _type:
                let
                  baseName = baseNameOf path;
                in
                baseName != "_build"
                && baseName != "_opam"
                && baseName != ".direnv"
                && baseName != "result"
                && !pkgs.lib.hasSuffix ".swp" baseName
                && !pkgs.lib.hasSuffix ".swo" baseName;
            };
          in
          pkgs.runCommand "check-format"
            {
              nativeBuildInputs = [
                pkgs.nixfmt-rfc-style
                pkgs.statix
                pkgs.deadnix
                scope'.ocamlformat
              ];
            }
            ''
              set -euo pipefail

              echo "Checking Nix formatting..."
              nixfmt --check ${src}/**/*.nix || {
                echo "ERROR: Run 'nix fmt' to fix."
                exit 1
              }

              echo "Checking Nix with statix..."
              statix check ${src} || exit 1

              echo "Checking for dead Nix code..."
              deadnix --fail ${src} || exit 1

              echo "Checking OCaml formatting..."
              find ${src} -name "*.ml" -o -name "*.mli" | while read -r file; do
                ocamlformat --check "$file" || {
                  echo "ERROR: $file not formatted. Run 'nix fmt'."
                  exit 1
                }
              done

              echo "All format checks passed."
              touch $out
            '';

        # Test execution
        tests =
          let
            testPackage = if localPackagesQuery ? test then scope'.test else null;
          in
          if testPackage == null then
            pkgs.runCommand "no-tests" { } ''
              echo "No test package found. Skipping."
              touch $out
            ''
          else
            pkgs.runCommand "run-tests"
              {
                nativeBuildInputs = [
                  testPackage
                  pkgs.dune_3
                ];
                buildInputs = testPackage.propagatedBuildInputs or [ ];
              }
              ''
                set -euo pipefail

                echo "Running test suite..."
                cp -r ${testPackage.src} ./source
                chmod -R +w ./source
                cd ./source

                dune runtest --display=short --error-reporting=twice || {
                  echo "ERROR: Tests failed."
                  exit 1
                }

                echo "All tests passed."
                touch $out
              '';

        # Documentation build
        docs =
          let
            docPackage =
              if localPackagesQuery ? test then
                scope'.test
              else if localPackagesQuery != { } then
                builtins.head (builtins.attrValues localPackages)
              else
                null;
          in
          if docPackage == null then
            pkgs.runCommand "no-docs" { } ''
              echo "No packages found. Skipping docs."
              touch $out
            ''
          else
            pkgs.runCommand "build-docs"
              {
                nativeBuildInputs = [
                  docPackage
                  pkgs.dune_3
                  scope'.odoc
                ];
                buildInputs = docPackage.propagatedBuildInputs or [ ];
              }
              ''
                set -euo pipefail

                echo "Building documentation..."
                cp -r ${docPackage.src} ./source
                chmod -R +w ./source
                cd ./source

                dune build @doc --display=short || {
                  echo "ERROR: Documentation build failed."
                  exit 1
                }

                echo "Documentation built successfully."
                mkdir -p $out
                cp -r _build/default/_doc/_html/* $out/ || true
                touch $out/SUCCESS
              '';
      };
    };
}
