{ config, pkgs, ... }:

{
  imports =
    [ 
    /etc/nixos/hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  services.upower.enable = false; # if you don't need it
  powerManagement.enable = false;

  networking.hostName = "nixos"; # Define your hostname.

    networking.networkmanager.enable = true;

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

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # iHD, for 8th gen+
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
    ];
  };

  services.xserver.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.setPath.enable = true;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "dave";
  };

  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  console.keyMap = "uk";

  services.printing.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;  

  services.pulseaudio.enable = false;

  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.dave = {
    isNormalUser = true;
    description = "Dave Nicholson";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    kitty
      neovim
      git
      tree
      xclip
      bat
      wlogout
      playerctl
      tremc

      quickshell
      qt6.qt5compat

  ];

  services.transmission = {
  enable = true;
  settings = {
    download-dir = "/home/dave/Downloads";
    rpc-bind-address = "127.0.0.1"; # Only allow local access
  };
};
systemd.services.transmission.serviceConfig.ReadWritePaths = [ "/home/dave/Downloads" ];

  environment.sessionVariables = {
    QML_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml";
  };

  services.openssh.enable = true;

  services.kvmux.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.firewall.allowedTCPPorts = [ 7777 4242 ];


  system.stateVersion = "25.11"; # Did you read the comment?

}
