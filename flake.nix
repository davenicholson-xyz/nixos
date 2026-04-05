{

  description = "One flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; 

    };

    claude-code.url = "github:sadjow/claude-code-nix";

    govista.url = "github:davenicholson-xyz/govista";
    nixvim.url = "github:nix-community/nixvim";
    kvmux.url = "github:davenicholson-xyz/kvmux";
  };

  outputs = { self, nixpkgs, home-manager, claude-code, govista, nixvim, kvmux, ... }:
  {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit kvmux; };
        modules = [
          { 
           nixpkgs.hostPlatform.system = "x86_64-linux"; 
           nixpkgs.overlays = [ claude-code.overlays.default ];
          }
          ./configuration.nix
          ./modules/kvmux-service.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit govista; inherit nixvim; inherit kvmux; };
            home-manager.users.dave = import ./home.nix;
            home-manager.backupFileExtension = "bak";
          }
        ];
      };
    };
  };

}
