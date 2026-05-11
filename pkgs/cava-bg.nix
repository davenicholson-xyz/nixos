{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, wayland, wayland-protocols, libxkbcommon, mesa, libGL, vulkan-loader, cava }:

let
  src = fetchFromGitHub {
    owner = "leriart";
    repo = "cava-bg";
    rev = "95ee05645b968661c86e7f2dca3ade3924a2097f";
    hash = "sha256-GZh5uguUEFIVoawwYFroqTLh7r0u1AezgP3ZzW1nW8w=";
  };
in
rustPlatform.buildRustPackage {
  pname = "cava-bg";
  version = "0.2.2";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "smithay-client-toolkit-0.20.0" = "sha256-rFNSzm1003spYHdzlvCyb7PWGMOJibUq/Ek3F5HABkM=";
    };
  };

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs = [ wayland wayland-protocols libxkbcommon mesa libGL vulkan-loader cava ];

  postInstall = ''
    wrapProgram $out/bin/cava-bg \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ vulkan-loader wayland libGL mesa ]}"
  '';
}
