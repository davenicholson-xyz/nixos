{ config, pkgs, ... }:

{
  programs.hyprland = {
	   enable = true;
	   xwayland.enable = true;
	   systemd.setPath.enable = true;
	 };  
  
}
