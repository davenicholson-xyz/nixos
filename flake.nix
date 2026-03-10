{

  description = "One flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; 

    };

    pyvista.url = "github:davenicholson-xyz/pyvista";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs = { self, nixpkgs, home-manager, pyvista, nixvim, ... }:
  {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        modules = [
          { nixpkgs.hostPlatform.system = "x86_64-linux"; }
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit pyvista; inherit nixvim; };
            home-manager.users.dave = import ./home.nix;
            home-manager.backupFileExtension = "bak";
          }
        ];
      };
    };
  };

}
