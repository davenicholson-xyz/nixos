{ pkgs, ... }:

{
  home.packages = [
    (pkgs.stdenv.mkDerivation {
     name = "wallchemybar";
     src = pkgs.fetchurl {
     url = "https://github.com/davenicholson-xyz/wallchemybar/releases/download/0.1.0/wallchemybar_0.1.0_amd64.deb";
     hash = "sha256-XmFUitHdRFJk9tQyN28aBOKk/QPP0ZdaLnepLVVSjLQ=";
     };
     nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];
     buildInputs = [
     pkgs.webkitgtk_4_1
     pkgs.libayatana-appindicator
       pkgs.libappindicator-gtk3

     pkgs.openssl
     pkgs.glib
     pkgs.gtk3
     ];
     unpackPhase = "dpkg-deb -x $src .";
     installPhase = ''
     mkdir -p $out/bin
     cp usr/bin/wallchemybar $out/bin/
     '';
     })
  ];
}
