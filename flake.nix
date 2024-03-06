{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, config, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.lib;
      let
        pkgs = import nixpkgs { inherit system; };
        beamPackages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlangR26;
        elixir = beamPackages.elixir_1_16;

        pname = "kea-lease-viewer";
        version = "0.1.0";
      in
      {
        packages.default = beamPackages.mixRelease {
          inherit version pname elixir;

          removeCookie = false;
          mixNixDeps = with pkgs; import ./deps.nix { inherit lib beamPackages; };
          src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
        };

        devShell = pkgs.mkShell
          {
            buildInputs = [ elixir ];
            shellHook = ''
              export PORT=4000
              iex -S mix
            '';
          };

        nixosModules.default =
          {
            options = {
              services.${pname} = {
                enable = mkEnableOption "${pname} service";

                keaSocketPath = mkOption {
                  type = types.path;
                  description = "Path to the kea control socket. It needs to have read permissions for the '${pname}' user. Also the libdhcp_lease_cmds hook needs to be enabled.";
                };

                port = mkOption {
                  type = types.int;
                  default = 80;
                  description = "Port to listen on";
                };
              };
            };

            config =
              let
                cfg = config.services.${pname};
              in
              {
                users.users.${pname} = {
                  name = pname;
                  isSystemUser = true;
                };

                systemd.services.${pname} = {
                  enable = cfg.enable;
                  wantedBy = [ "multi-user.target" ];
                  after = [ "network.target" ];

                  environment = {
                    PORT = cfg.port;
                    KEA_SOCKET_PATH = cfg.kea_socket_path;
                  };

                  serviceConfig = {
                    Type = "exec";
                    User = pname;

                    ExecStart = ''
                      ${self.packages.${system}.default}/bin/release start
                    '';
                    ExecStop = ''
                      ${self.packages.${system}.default}/bin/release stop
                    '';

                    Restart = "on-failure";

                    # Add capability to bind on port 80
                    CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
                    AmbientCapabilities = "CAP_NET_BIND_SERVICE";
                  };

                };
              };
          };
      }
    );
}


