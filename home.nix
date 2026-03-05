{ config, pkgs, pychemy, ... }: {

  imports = [
    ./modules/neovim.nix
    ./modules/tmux.nix
    ./modules/pychemy.nix
  ];

  home.username = "dave";
  home.homeDirectory = "/home/dave";

  home.sessionPath = [ "$HOME/nixos/bin" ];

  home.stateVersion = "25.11"; 

  home.packages = with pkgs; [
    brave
    swww
    kitty
    gh
    claude-code
    yazi
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --impure --flake /home/dave/nixos#nixos";
    };

    history.size = 10000;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

 programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "Dave Nicholson";
        email = "me@davenicholson.xyz";
      };
      init.defaultBranch = "main";
    };
  }; 

  programs.pychemy = {
    enable = true;
    settings = {
      username = "yourname";
      apiKey = "your-api-key";
      script = "/path/to/your/setwallpaper.sh";
      thumbSize = "l";
      closeOnSelect = true;
    };
  };

  programs.home-manager.enable = true;
                       }
