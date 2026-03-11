{ config, lib, pkgs, govista, ... }:

let
  cfg = config.programs.govista;

  tomlFormat = pkgs.formats.toml {};

  configFile = tomlFormat.generate "config.toml" (
    lib.filterAttrs (_: v: v != null && v != "") {
      api_key           = cfg.settings.apiKey;
      username          = cfg.settings.username;
      query             = cfg.settings.query;
      categories        = cfg.settings.categories;
      purity            = cfg.settings.purity;
      "min-resolution"  = cfg.settings.minResolution;
      script            = cfg.settings.script;
      output            = if cfg.settings.output then true else null;
      "close-on-select" = if cfg.settings.closeOnSelect then true else null;
    }
  );

in {
  options.programs.govista = {
    enable = lib.mkEnableOption "govista wallhaven gallery browser";

    settings = {
      apiKey = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Wallhaven API key";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Wallhaven username";
      };
      query = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Default search query";
      };
      categories = lib.mkOption {
        type = lib.types.str;
        default = "111";
        description = "Category bitmask (general/anime/people)";
      };
      purity = lib.mkOption {
        type = lib.types.str;
        default = "100";
        description = "Purity bitmask (sfw/sketchy/nsfw)";
      };
      minResolution = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Minimum resolution e.g. 1920x1080";
      };
      script = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to script run on wallpaper selection";
      };
      output = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Print selected wallpaper path to stdout";
      };
      closeOnSelect = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Close window after selecting a wallpaper";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ govista.packages.${pkgs.system}.default ];

    xdg.configFile."govista/config.toml".source = configFile;
  };
}
