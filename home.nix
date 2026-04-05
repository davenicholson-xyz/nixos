{ config, pkgs, lib, govista, nixvim, kvmux, ... }:

{

  imports = [
    ./modules/nixvim.nix
    ./modules/tmux.nix
    ./modules/govista.nix
    ./modules/kvmux.nix
  ];

  home.username = "dave";
  home.homeDirectory = "/home/dave";

  home.sessionPath = [ "$HOME/nixos/bin" ];

  home.sessionVariables = {
    NH_FLAKE = "/home/dave/nixos";
  };

  home.stateVersion = "25.11"; 

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Classic";
    size = 24;
    package = pkgs.bibata-cursors;
  };

  home.file.".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/hypr";
  home.file.".config/niri".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/niri";

  home.file.".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/kitty";
  home.file.".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/quickshell";
  home.file.".config/govista".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/config/govista";

  home.packages = with pkgs; [
      brave
      # swww
      awww
      kitty
      gh
      claude-code
      yazi
      spotify
      thunderbird
      mpv

      ripgrep
      jq
      grim
      slurp
      fastfetch
      trash-cli
      nh
      btop
      cava

      nerd-fonts.jetbrains-mono
      nerd-fonts.sauce-code-pro

      niri
      xwayland
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
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
      ssh = "ssh-hypr";
      currentwp = ''xdg-open https://wallhaven.cc/w/$(swww query | grep -oP '(?<=image: )[^\s,]+' | cut -d"/" -f6 | cut -d. -f1)'';

      ehome = "nvim /home/dave/nixos/home.nix";
      ehypr = "nvim /home/dave/nixos/config/hypr/hyprland.conf";
      eniri = "nvim /home/dave/nixos/config/niri/config.kdl";

      rebuild = "nh os switch --impure";
      update = "nh os switch --impure -u";
      cleanup = "nh clean all --keep 3";
    };


    initContent = ''
autoload -Uz vcs_info add-zsh-hook
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '!'
zstyle ':vcs_info:git:*' stagedstr '+'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f%F{yellow}''${vcs_info_msg_0_}%f %(?.%F{green}❯%f.%F{red}❯%f) '

# Auto-rename tmux session to current directory basename on cd
function _tmux_rename_session() {
  [[ -n "$TMUX" ]] && tmux rename-session "$(basename "$PWD")" 2>/dev/null
}
add-zsh-hook chpwd _tmux_rename_session
_tmux_rename_session
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


  programs.kvmux.enable = true;

  programs.govista.enable = true;

  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

}
