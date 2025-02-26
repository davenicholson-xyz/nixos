{ config, pkgs, ... }:

{

  imports =
  [
      ../../modules/home-manager/git.nix
      ../../modules/home-manager/zsh.nix
  ];


  home.username = "dave";
  home.homeDirectory = "/home/dave";

  home.stateVersion = "24.11";

  home.file.".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/hypr";
  home.file.".config/i3".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/i3";
  home.file.".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/kitty";

  home.packages = with pkgs; [
  	google-chrome

  	helix
    tree
    yazi
    lazygit
    trash-cli

    feh
  ];

  fonts.fontconfig.enable = true;
  
  home.sessionVariables = {
    EDITOR = "hx";
  };

  home.sessionPath = [
    "/home/dave/.local/bin"
    "/home/dave/.cargo/bin"
  ];

   programs.direnv = {
      enable = true;
      # silent = true;
  };

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

}
