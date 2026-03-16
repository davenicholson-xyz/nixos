{ config, lib, pkgs, kvmux, ... }:
{
  options.programs.kvmux.enable = lib.mkEnableOption "kvmux software KVM switch";

  config = lib.mkIf config.programs.kvmux.enable {
    home.packages = [ kvmux.packages.${pkgs.system}.default ];
  };
}
