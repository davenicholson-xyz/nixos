{ pkg, ... }:

{
  virtualisation.docker = {
    enable = true;
  };

  systemd.services.dockercompose = {
    description = "Docker compose service";
    after = [ "network-online.target" "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      WorkingDirectory = "/home/dave/nixos/docker";
      ExecStart = "/run/current-system/sw/bin/docker compose up -d";
      ExecStop = "/run/current-system/sw/bin/docker compose down";
      Restart = "always";
      User = "dave";
      Group = "docker";
      Environment = "DOCKER_HOST=unix:///var/run/docker.sock";
      ExecStartPre = "/run/current-system/sw/bin/bash -c 'test -S /var/run/docker.sock'";
    };
  };

}
