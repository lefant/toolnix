{ config, ... }:
let
  features = config.toolnix.features;
in {
  config.toolnix.profiles.homeManager.defaultModule = {
    imports = [
      ({ ... }: {
        _module.args.toolnixFeatures = features;
      })
      features.requiredBaseline.homeManagerModule
      features.agentBaseline.homeManagerOptionModule
      features.compoundEngineering.homeManagerOptionModule
      features.agentBrowser.homeManagerOptionModule
      features.browserTools.homeManagerOptionModule
      features.hostControl.homeManagerOptionModule
      ../../internal/profiles/home-manager/core.nix
    ];
  };
}
