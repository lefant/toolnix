{ pkgs, lib, inputs }:
let
  browserToolsData = import ./browser-tools.nix { inherit pkgs lib inputs; };
in browserToolsData.agentBrowser
