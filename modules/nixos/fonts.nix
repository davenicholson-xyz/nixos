{ config, pkgs, ... }:

{
   fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      roboto
      font-awesome
      (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];
}
