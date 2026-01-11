{
  perSystem = {
    craneLib,
    commonArgs,
    cargoArtifacts,
    ...
  }: let
    buildPkg = name: cargoExtraArgs:
      craneLib.buildPackage (
        commonArgs
        // {
          inherit cargoArtifacts;
          pname = name;
          cargoExtraArgs = cargoExtraArgs;
          CARGO_PROFILE = "release";
        }
      );
  in let
    my-cli = buildPkg "my-cli" "-p my-cli";
    my-server = buildPkg "my-server" "-p my-server";
  in {
    packages = {
      inherit my-cli my-server;
      default = my-cli;
    };

    apps = {
      my-cli = {
        type = "app";
        program = "${my-cli}/bin/my-cli";
      };
      my-server = {
        type = "app";
        program = "${my-server}/bin/my-server";
      };
    };
  };
}
