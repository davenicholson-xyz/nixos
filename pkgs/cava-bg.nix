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

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ wayland wayland-protocols libxkbcommon mesa libGL cava ];
}
