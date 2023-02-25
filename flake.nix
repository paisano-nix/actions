{
  description = "Small set of shared base actions for Paisano-based projects.";

  outputs = {nixpkgs, ...}: let
    mkCommand = import ./command.nix {inherit nixpkgs;};
    actions = import ./actions.nix {
      inherit (nixpkgs) lib;
      inherit nixpkgs mkCommand;
    };
  in {
    inherit mkCommand;
    inherit (actions) build run;
  };
}
