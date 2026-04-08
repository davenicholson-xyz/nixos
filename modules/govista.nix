{ config, lib, pkgs, govista, ... }:

let
  cfg = config.programs.govista;
in {
  options.programs.govista = {
    enable = lib.mkEnableOption "govista wallhaven gallery browser";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ govista.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  };
}
