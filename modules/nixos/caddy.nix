{ pkgs, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts."www.lodgeserver.net".extraConfig = ''
      redir https://lodgeserver.net{uri}
    '';

    virtualHosts."homepage.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.1.21:3000
    '';

    virtualHosts."adblock.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.0.9
    '';

    virtualHosts."plex.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.1.23:32400
    '';

    virtualHosts."qbittorrent.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.78.192:8080 
    '';

    virtualHosts."proxmox.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.69.40:8006
    '';

    virtualHosts."wireguard.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.0.10:51821
    '';

    virtualHosts."omv.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.69.69:80
    '';

    virtualHosts."http://cameras.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.157.19:8090
    '';
  };

}
