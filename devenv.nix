{ pkgs, lib, config, inputs, ... }:
import ./modules/devenv/default.nix { inherit pkgs lib config inputs; }
