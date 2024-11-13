{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
        version = "0.2.0";
        beamPackages = pkgs.beamPackages;
        mix_release = beamPackages.mixRelease {
          inherit version pname;
          removeCookie = false;

          mixNixDeps = import ./deps.nix {
            inherit beamPackages;
            lib = pkgs.lib;
            overrides = final: prev: {
              syslog = prev.syslog.override {buildPlugins = [beamPackages.pc];};
            };
          };

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

            adminSubnets = mkOption {
              type = types.listOf types.str;
              description = "Subnets that can see all leases.";
              default = [];
            };

            disabledSubnets = mkOption {
              type = types.listOf types.str;
              description = "Subnets that cannot see any leases.";
              default = [];
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
              ADMIN_SUBNETS = builtins.concatStringsSep "," cfg.adminSubnets;
              DISABLED_SUBNETS = builtins.concatStringsSep "," cfg.disabledSubnets;
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
