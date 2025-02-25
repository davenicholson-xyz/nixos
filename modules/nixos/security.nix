{ config, pkg, ... }:

{
    security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
