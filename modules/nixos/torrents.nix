{ config, pkgs, ... }:
{
   environment.systemPackages = [
    pkgs.qbittorrent-nox
  ];

  systemd.services.qbittorrent-nox = { 
    description = "qBittorrent-nox service"; 
    documentation = ["man:qbittorrent-nox(1)"]; 
    wants = ["network-online.target"]; 
    after = ["local-fs.target" "network-online.target" "nss-lookup.target"]; 
    wantedBy = ["multi-user.target"]; 
    serviceConfig = { 
      Type = "simple"; PrivateTmp = "false"; User = "dave"; 
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox"; 
      TimeoutStopSec = 1800; 
    }; 
  };
  
}
