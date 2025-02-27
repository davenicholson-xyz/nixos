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

  home.packages = with pkgs; [
  	helix
    tree
    yazi
    lazygit
    trash-cli
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };

  home.sessionPath = [
    # "/home/dave/.local/bin"
    # "/home/dave/.cargo/bin"
  ];

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

}
