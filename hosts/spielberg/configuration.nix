{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix

      ../../modules/nixos/boot.nix
      ../../modules/nixos/locale.nix

      ../../modules/nixos/caddy.nix

      # ../../modules/nixos/torrents.nix
      # ../../modules/nixos/vpn_network.nix

      ../../docker/network/docker-compose.nix
      ../../docker/torrent/docker-compose.nix
      ../../docker/indexers/docker-compose.nix
      ../../docker/dashboard/docker-compose.nix
    ];

  networking = {
    hostName = "spielberg";

    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "172.16.1.11";
        prefixLength = 16;
      }];
    };

    defaultGateway = "172.16.0.1";
    nameservers = [ "172.16.0.9" ];
  };

  networking.networkmanager.enable = true;

  services.nfs = {
    server.enable = true;
  };

  fileSystems."/mnt/media" = {
    device = "172.16.69.69:/export/media";
    fsType = "nfs";
  };
  
  users.users.dave = {
    isNormalUser = true;
    description = "Dave";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      compose2nix
      screen
      iproute2
      btop
    ];
  };

  services.getty.autologinUser = "dave";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  ];

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    user = "dave";
    openFirewall = true;
  };

  services.sonarr= {
    enable = true;
    user = "dave";
    openFirewall = true;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
    	"dave" = import ./home.nix;
    };
  };

  services.openssh.enable = true;

  networking.firewall = {
    enable = false;
  };

  system.stateVersion = "24.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
