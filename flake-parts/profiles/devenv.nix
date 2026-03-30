{ config, ... }:
let
  features = config.toolnix.features;
in {
  config.toolnix.profiles.devenv.defaultModule = { ... }: {
    imports = [
      ({ ... }: {
        _module.args.toolnixFeatures = features;
      })
      features.requiredBaseline.devenvModule
      features.opinionatedShell.devenvOptionModule
      features.agentBrowser.devenvOptionModule
      ../../internal/profiles/devenv/core.nix
    ];
  };
}
