{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    newSession = true;
    escapeTime = 0;
    mouse = true;
    clock24 = true;
    historyLimit = 50000;
    keyMode = "vi";

    extraConfig = ''
      set -g renumber-windows on    
      bind -n C-h previous-window
      bind -n C-l next-window
    '';
  };

}
