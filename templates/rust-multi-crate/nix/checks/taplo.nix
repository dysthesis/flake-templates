{
  craneLib,
  pkgs,
  src,
  ...
}:
craneLib.taploFmt {
  src = pkgs.lib.sources.sourceFilesBySuffices src [".toml"];
}
