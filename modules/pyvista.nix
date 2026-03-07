{ config, lib, pkgs, pyvista, ... }:

let
  cfg = config.programs.pyvista;

  tomlFormat = pkgs.formats.toml {};

  configFile = tomlFormat.generate "config.toml" (
    lib.filterAttrs (_: v: v != null && v != "") {
      api_key           = cfg.settings.apiKey;
      username          = cfg.settings.username;
      query             = cfg.settings.query;
      categories        = cfg.settings.categories;
      purity            = cfg.settings.purity;
      "thumb-size"      = cfg.settings.thumbSize;
      "min-resolution"  = cfg.settings.minResolution;
      script            = cfg.settings.script;
      "close-on-select" = if cfg.settings.closeOnSelect then true else null;
    }
  );

in {
  options.programs.pyvista = {
    enable = lib.mkEnableOption "pyvista wallhaven gallery browser";

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
      thumbSize = lib.mkOption {
        type = lib.types.enum [ "sm" "m" "l" "xl" ];
        default = "m";
        description = "Thumbnail size";
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
      closeOnSelect = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Close window after selecting a wallpaper";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pyvista.packages.${pkgs.system}.default ];

    xdg.configFile."pyvista/config.toml".source = configFile;
  };
}
