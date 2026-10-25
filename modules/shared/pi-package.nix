{ pkgs, inputs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  # Bundle Pi with a fixed prebuilt runtime; never compile Bun itself.
  bun = pkgs.bun.overrideAttrs {
    version = "1.4.4";
    src = pkgs.fetchurl ({
      x86_64-linux = {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.4/bun-linux-x64-baseline.zip";
        sha256 = "e0446eb55995772eb9894bebae9a6be368d985a8b9271ee124486f9946eedd76";
      };
      aarch64-darwin = {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.4/bun-darwin-aarch64.zip";
        sha256 = "c240d7f0ccb90c263a849fcdb09b7ee62630d921348ed6aafda86b9d577bc510";
      };
    }.${system});
  };
in inputs.llm-agents.packages.${system}.pi.override { inherit bun; }
