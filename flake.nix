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
          iex -S mix
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
              type = types.string;
              default = "80";
              description = "Port to listen on";
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

          # systemd.serv
          systemd.services.${pname} = {
            enable = cfg.enable;
            wantedBy = ["multi-user.target"];
            after = ["network.target"];

            environment = {
              PORT = cfg.port;
              KEA_SOCKET_PATH = cfg.keaSocketPath;
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

              # Add capability to bind on port 80
              CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
              AmbientCapabilities = "CAP_NET_BIND_SERVICE";
            };
          };
        };
      };
  };
}
