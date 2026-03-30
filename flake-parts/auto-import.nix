{ dir }:
let
  entries = builtins.readDir dir;
  names = builtins.attrNames entries;
  nixFiles = builtins.filter (
    name:
    name != "default.nix"
    && name != "auto-import.nix"
    && entries.${name} == "regular"
    && builtins.match ".*\\.nix" name != null
  ) names;
in
map (name: import (dir + "/${name}")) nixFiles
