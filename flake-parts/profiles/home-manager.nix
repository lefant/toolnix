{ config, ... }:
let
  features = config.toolnix.features;
in {
  config.toolnix.profiles.homeManager.agentsModule = {
    imports = [
      ({ ... }: {
        _module.args.toolnixFeatures = features;
      })
      features.agentBaseline.homeManagerOptionModule
      features.agentBrowser.homeManagerOptionModule
      features.compoundEngineering.homeManagerOptionModule
      ../../internal/profiles/home-manager/agents.nix
    ];
  };
  config.toolnix.profiles.homeManager.defaultModule = {
    imports = [
      features.requiredBaseline.homeManagerModule
      config.toolnix.profiles.homeManager.agentsModule
      features.browserTools.homeManagerOptionModule
      features.hitlBrowserAutomation.homeManagerOptionModule
      features.hostControl.homeManagerOptionModule
      ../../internal/profiles/home-manager/core.nix
    ];
    toolnix.agentLinuxForceCompatibility = true;
  };
}
