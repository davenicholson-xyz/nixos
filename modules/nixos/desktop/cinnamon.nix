{ config, pkgs, ...}:

{
  services.xserver.enable = true;
  services.libinput.enable = true;

  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;
}
