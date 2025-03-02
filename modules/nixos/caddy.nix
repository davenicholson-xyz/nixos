{ pkgs, ... }:

{
  services.caddy = {
    enable = true;

    # virtualHosts."www.lodgeserver.net".extraConfig = ''
    #   redir https://lodgeserver.net{uri}
    # '';

    virtualHosts."dashboard.lodgeserver.net".extraConfig = ''
      reverse_proxy localhost:3000
    '';

    virtualHosts."adguard.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.0.9
    '';

    virtualHosts."plex.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.1.23:32400
    '';

    virtualHosts."qbittorrent.lodgeserver.net".extraConfig = ''
      reverse_proxy localhost:8080 
    '';

    virtualHosts."prowlarr.lodgeserver.net".extraConfig = ''
      reverse_proxy localhost:9696
    '';

    virtualHosts."radarr.lodgeserver.net".extraConfig = ''
      reverse_proxy localhost:7878
    '';

    virtualHosts."sonarr.lodgeserver.net".extraConfig = ''
      reverse_proxy localhost:8989
    '';

    virtualHosts."proxmox.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.69.40:8006
    '';

    virtualHosts."wireguard.lodgeserver.net".extraConfig = ''
      reverse_proxy localhost:51821
    '';

    virtualHosts."omv.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.69.69:80
    '';

  };

}
