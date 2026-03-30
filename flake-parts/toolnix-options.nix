{ lib, ... }: {
  options.toolnix.internal = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Internal merged registry for toolnix flake-parts internals.";
  };

  options.toolnix.features = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Merged feature registry published by toolnix flake-parts modules.";
  };

  options.toolnix.profiles = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Merged profile registry published by toolnix flake-parts modules.";
  };
}
