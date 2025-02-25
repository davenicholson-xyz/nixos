{ config, pkgs, ... }:

{
  
  programs.git = {
    enable = true;
    userName = "Dave Nicholson";
    userEmail = "me@davenicholson.xyz";
  };

}
