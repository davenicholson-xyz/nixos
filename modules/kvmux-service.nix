{ config, lib, pkgs, kvmux, ... }:
{
  options.services.kvmux.enable = lib.mkEnableOption "kvmux server";

  config = lib.mkIf config.services.kvmux.enable {
    systemd.services.kvmux = {
      description = "kvmux software KVM server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${kvmux.packages.${pkgs.system}.default}/bin/kvmux-server";
        Restart = "on-failure";
      };
    };
  };
}
