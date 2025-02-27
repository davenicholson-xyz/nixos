{ pkgs, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts."www.lodgeserver.net".extraConfig = ''
      redir https://lodgeserver.net{uri}
    '';

    virtualHosts."homepage.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.164.62:3000
    '';

    virtualHosts."pihole.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.0.10
    '';

    virtualHosts."plex.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.245.192:32400
    '';

    virtualHosts."qbittorrent.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.78.192:8080 
    '';

    virtualHosts."proxmox.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.69.40:8006
    '';

    virtualHosts."http://cameras.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.157.19:8090
    '';
  };

}
