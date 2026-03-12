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
    extraConfig = builtins.readFile /home/dave/nixos/config/tmux/.tmux.conf;
  };
}
