{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    devShell = forAllSystems (system:
      nixpkgs.legacyPackages.${system}.mkShell
      {
        buildInputs = [nixpkgs.legacyPackages.${system}.elixir];
        shellHook = ''
          export PORT=4000
          export LISTEN_ADDRESS=127.0.0.1
          iex -S mix
          exit 0
        '';
      });

    nixosModules.default = {
      config,
      pkgs,
      ...
    }:
      with nixpkgs.lib; let
        pname = "kea-lease-viewer";
        version = "0.1.0";
        mix_release = pkgs.beamPackages.mixRelease {
          inherit version pname;

          removeCookie = false;
          mixNixDeps = with pkgs; import ./deps.nix {inherit lib beamPackages;};
          src = pkgs.nix-gitignore.gitignoreSource [] ./.;
        };
      in {
        options = {
          services.${pname} = {
            enable = mkEnableOption "${pname} service";

            keaSocketPath = mkOption {
              type = types.path;
              description = "Path to the kea control socket. It needs to have read permissions for the '${pname}' user. Also the libdhcp_lease_cmds hook needs to be enabled.";
            };

            port = mkOption {
              type = types.int;
              default = 4000;
              description = "Port to listen on.";
            };

            listenAddress = mkOption {
              type = types.str;
              description = "Address to listen on.";
              default = "127.0.0.1";
            };
          };
        };

        config = let
          cfg = config.services.${pname};
        in {
          users.users.${pname} = {
            name = pname;
            group = pname;
            isSystemUser = true;
          };
          users.groups.${pname} = {};

          systemd.services.${pname} = {
            enable = cfg.enable;
            wantedBy = ["multi-user.target"];
            after = ["network.target"];

            environment = {
              PORT = toString cfg.port;
              LISTEN_ADDRESS = cfg.listenAddress;
              KEA_SOCKET_PATH = cfg.keaSocketPath;
              RELEASE_DISTRIBUTION = "none";
            };

            serviceConfig = {
              Type = "exec";
              User = pname;

              ExecStart = ''
                ${mix_release}/bin/release start
              '';
              ExecStop = ''
                ${mix_release}/bin/release stop
              '';

              Restart = "on-failure";
            };
          };
        };
      };
  };
}
