{ config, pkgs, ...}:

{
  users.users.dave = {
    isNormalUser = true;
    description = "Dave Nicholson";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  programs.zsh.enable = true;
  users.users.dave.shell = pkgs.zsh;

}
