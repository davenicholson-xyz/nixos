{ config, pkgs, ... }:

let
  aliases = {
   ns = "sudo nixos-rebuild switch --flake /home/dave/nixos#default";
};
in
{
   programs.zsh = {
     enable = true;
    shellAliases = aliases;
    enableCompletion = true;
    history = {
      size = 10000;
    };
    oh-my-zsh = {
      enable = true;
      theme = "eastwood";
      plugins = [
        "git"
        "history"
      ];
    };
  };
}
