{
  lib,
  nixpkgs,
  mkCommand,
}: let
  contextFreeDrv = target: lib.unsafeDiscardStringContext target.drvPath;

  build = currentSystem: target:
    mkCommand currentSystem {
      name = "build";
      description = "build artifact";
      command = ''
        # ${target}
        nix build ${contextFreeDrv target}
      '';
      targetDrv = target.drvPath;
      proviso =
        # bash
        ''
          function proviso() {
            local -n input=$1
            local -n output=$2

            local drvs
            local -a uncached

            # FIXME: merge upstream to avoid any need for runtime context
            command nix build github:divnix/nix-uncached/v2.13.1

            drvs=$(command jq -r '.targetDrv | select(. != "null")' <<< "''${input[@]}")

            uncached_json=$(result/bin/nix-uncached $drvs)

            mapfile -t uncached < <(command jq -r 'to_entries[]|select(.value != [])|.key' <<< "$uncached_json")

            if [[ -n ''${uncached[*]} ]]; then
              local list filtered

              list=$(command jq -ncR '[inputs]' <<< "''${uncached[@]}")
              filtered=$(command jq -c 'select([.targetDrv] | inside($p))' --argjson p "$list" <<< "''${input[@]}")

              output=$(command jq -cs '. += $p' --argjson p "$output" <<< "$filtered")
            fi
          }
        '';
    };

  run = currentSystem: target: let
    programName =
      target.meta.mainProgram
      or (lib.getName target);
  in
    mkCommand currentSystem {
      name = "run";
      description = "run artifact";
      # this is the exact sequence mentioned by the `nix run` docs
      # and so should be compatible
      command = ''
        ${target.program or "${target}/bin/${programName}"} "$@"
      '';
    };
in {inherit build run;}
