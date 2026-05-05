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
      features.browserTools.devenvOptionModule
      features.compoundEngineering.devenvOptionModule
      ../../internal/profiles/devenv/core.nix
    ];
  };
}
