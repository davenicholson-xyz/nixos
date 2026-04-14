{ lib, rustPlatform, fetchFromGitHub, pkg-config, wayland, wayland-protocols, libxkbcommon, mesa, libGL, cava }:

rustPlatform.buildRustPackage {
  pname = "cava-bg";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "leriart";
    repo = "cava-bg";
    rev = "YOUR_COMMIT_HASH";
    hash = "sha256-jAN6M2yWEdpN4jG3EWDf4i2sMbj9qhYASKIsU2NVXqs=";
  };

  cargoPatches = [ ./add-cargo-lock.patch ];

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "smithay-client-toolkit-0.20.0" = "sha256-rFNSzm1003spYHdzlvCyb7PWGMOJibUq/Ek3F5HABkM=";
    };
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ wayland wayland-protocols libxkbcommon mesa libGL cava ];
}
