# Kea Lease Viewer

A lightweight, read-only dashboard that shows all dhcp leases for a subnet. The main purpose is to give users of a network an overview over what other hosts are reachable on the same subnet.

It is intended to run on the same host as kea and communicates via the kea control socket more details in the [kea documentation](https://kea.readthedocs.io/en/latest/arm/dhcp4-srv.html#management-api-for-the-dhcpv4-server). Make sure the socket is readable by the `kea-lease-viewer` user. Also the [libdhcp_lease_cmds](https://kea.readthedocs.io/en/latest/arm/hooks.html#libdhcp-lease-cmds-so-lease-commands-for-easier-lease-management) hook needs to be enabled.

The subnet is selected via the source address of the http request.

## Usage [nixos]

This project contains a flake.nix that provides a nixos module. 

You can use it as follows in your nixos project:

```nix
  inputs = {
    # ...
    kea-lease-viewer.url = "github:reimerei/kea-lease-viewer/main";
    # optional
    kea-lease-viewer.inputs.nixpkgs.follows = "nixpkgs";
  };
```

```nix
  imports = [
    inputs.kea-lease-viewer.nixosModules.default
  ];

  services.kea-lease-viewer = {
    enable = true;
    keaSocketPath = "/run/kea-dhcp4.sock";
    port = 4000;
  };
```

## Usage [elixir]

This can also be deployed like any other elixir project via `mix release`, copying the resulting release to the target and running it there. More details [here](https://hexdocs.pm/mix/Mix.Tasks.Release.html).