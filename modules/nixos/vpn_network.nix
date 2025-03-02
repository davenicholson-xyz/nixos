{ config, pkgs, lib, ... }:

{
 
  environment.systemPackages = with pkgs; [
    wireguard-tools
    iproute2
    iptables
  ];

  networking.wg-quick.interfaces.wg0.configFile = "/home/dave/mullvad/wg.conf";

}
