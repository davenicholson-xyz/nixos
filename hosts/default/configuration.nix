{ config, pkgs, inputs, ... }:

{
  imports =
  [
      ./hardware-configuration.nix

      ../../modules/nixos/boot.nix
      ../../modules/nixos/locale.nix
      ../../modules/nixos/network.nix
      ../../modules/nixos/users.nix
      ../../modules/nixos/ssh.nix
      ../../modules/nixos/security.nix
      # ../../modules/nixos/fonts.nix
 
      ../../modules/nixos/desktop/i3.nix
      # ../../modules/nixos/desktop/hyprland.nix
      # ../../modules/nixos/desktop/cinnamon.nix
   ];

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  hardware = {
    graphics.enable = true;
  };

  services.getty.autologinUser = "dave";

  environment.systemPackages = with pkgs; [
  	git
    kitty

    gcc
    rustc
    cargo
  ];

  fonts.packages = [
    pkgs.nerd-fonts.droid-sans-mono
  ];
  
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
    	"dave" = import ./home.nix;
    };
  };

  system.stateVersion = "24.11";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
