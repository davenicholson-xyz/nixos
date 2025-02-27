{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking = {
    hostName = "spielberg";

    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "172.16.1.11";
        prefixLength = 16;
      }];
    };

    defaultGateway = "172.16.0.1";
    nameservers = [ "172.16.0.10" ];
  };

  networking.networkmanager.enable = true;

  services.nfs = {
    server.enable = true;
  };

  fileSystems."/mnt/media" = {
    device = "172.16.69.69:/export/media";
    fsType = "nfs";
  };
  
  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  console.keyMap = "uk";

  users.users.dave = {
    isNormalUser = true;
    description = "Dave";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  services.getty.autologinUser = "dave";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  ];

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
      reverse_proxy 172.16.245.192.32400
    '';

    virtualHosts."qbittorrent.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.78.192.8080 
    '';

    virtualHosts."proxmox.lodgeserver.net".extraConfig = ''
      reverse_proxy 172.16.69.40:8006
    '';
  };

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

}
