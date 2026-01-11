{
  craneLib,
  pkgs,
  src,
  ...
}:
craneLib.mkCargoDerivation {
  inherit src;
  pname = "my-workspace-hakari";
  cargoArtifacts = null;
  doInstallCargoArtifacts = false;

  buildPhaseCargoCommand = ''
    cargo hakari generate --diff
    cargo hakari manage-deps --dry-run
    cargo hakari verify
  '';

  nativeBuildInputs = [pkgs.cargo-hakari];
}
