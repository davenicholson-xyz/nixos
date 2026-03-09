{ config, pkgs, lib, pyvista, nixvim, ... }: 

let 
apiKey = lib.strings.trim(builtins.readFile "/home/dave/.secrets/wallhaven-api-key");
in 
{

  imports = [
    ./modules/nixvim.nix
      ./modules/tmux.nix
      ./modules/pyvista.nix
  ];

  home.username = "dave";
  home.homeDirectory = "/home/dave";

  home.sessionPath = [ "$HOME/nixos/bin" ];

  home.stateVersion = "25.11"; 

  home.file.".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/hypr";
  home.file.".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/kitty";
  home.file.".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/quickshell";

  home.packages = with pkgs; [
    brave
      swww
      kitty
      gh
      claude-code
      yazi
      hyprlauncher
      spotify

      ripgrep
      jq
      grim
      slurp
      fastfetch
      trash-cli

      nerd-fonts.jetbrains-mono
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      share = true;        # share history across sessions
        ignoreDups = true;
    };

    shellAliases = {
      ll = "ls -l";
      lg = "lazygit";
      ehome = "nvim /home/dave/nixos/home.nix";
      update = "nix flake update --flake /home/dave/nixos && sudo nixos-rebuild switch --impure --flake /home/dave/nixos#nixos";
      rebuild = "sudo nixos-rebuild switch --impure --flake /home/dave/nixos#nixos";
    };


    initContent = ''
      autoload -Uz vcs_info
      precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
      zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
      zstyle ':vcs_info:git:*' check-for-changes true
      zstyle ':vcs_info:git:*' unstagedstr '!'
      zstyle ':vcs_info:git:*' stagedstr '+'
      setopt PROMPT_SUBST
      PROMPT='%F{cyan}%~%f%F{yellow}''${vcs_info_msg_0_}%f %(?.%F{green}❯%f.%F{red}❯%f) '
      '';

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


  programs.pyvista = {
    enable = true;
    settings = {
      username = "fatnic";
      apiKey = apiKey;
      categories = "101";
      purity = "110";
      script = "/home/dave/nixos/bin/setwallpaper";
      closeOnSelect = true;
      thumbSize = "sm";
      minResolution = "1920x1080";
    };
  };

  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

}
