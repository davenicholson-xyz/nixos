{ pkg, ... }:

{
  virtualisation.docker = {
    enable = true;
  };

  # systemd.services.dockercompose = {
  #   description = "Docker compose service";
  #   after = [ "network-online.target" "docker.service" ];
  #   requires = [ "docker.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     WorkingDirectory = "/home/dave/docker/vpnd/docker-compose.yml";
  #     ExecStart = "/run/current-system/sw/bin/docker compose up -d";
  #     ExecStop = "/run/current-system/sw/bin/docker compose down";
  #     # Restart = "always";
  #     Restart = "on-failure";
  #     RestartSec = "10s";
  #     User = "dave";
  #     Group = "docker";
  #     Environment = "DOCKER_HOST=unix:///var/run/docker.sock";
  #     ExecStartPre = "/run/current-system/sw/bin/bash -c 'test -S /var/run/docker.sock'";
  #     NoNewPrivileges = false;
  #   ProtectHome = false;
  #   ProtectSystem = false;
  #   PrivateTmp = false;
  #   PrivateDevices = false;
  #   ProtectKernelTunables = false;
  #   ProtectKernelModules = false;
  #   ProtectControlGroups = false;
  #   };
  # };

  systemd.services.nginx = {
  description = "Nginx Docker container";
  after = [ "network-online.target" "docker.service" ];
  requires = [ "docker.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "/run/current-system/sw/bin/docker run -d --name nginx -p 8080:80 nginx";
    ExecStop = "/run/current-system/sw/bin/docker stop nginx";
    Restart = "on-failure";
    RestartSec = "10s";
    User = "dave";
    Group = "docker";
    Environment = "DOCKER_HOST=unix:///var/run/docker.sock";
    ExecStartPre = "/run/current-system/sw/bin/bash -c 'test -S /var/run/docker.sock'";
  };

};

}
