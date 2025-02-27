{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix

      ../../modules/nixos/boot.nix
      ../../modules/nixos/locale.nix

      ../../modules/nixos/caddy.nix
      ../../modules/nixos/docker.nix
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
    packages = with pkgs; [];
  };

  services.getty.autologinUser = "dave";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  ];

  # services.flaresolverr = {
  #   enable = true;
  #   port = 8191;
  # };

  services.prowlarr = {
    enable = true;
  };

  services.radarr = {
    enable = true;
    user = "dave";
  };

  services.sonarr= {
    enable = true;
    user = "dave";
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

  networking.firewall.enable = false;

  system.stateVersion = "24.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
