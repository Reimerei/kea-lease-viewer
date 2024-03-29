{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    bandit = buildMix rec {
      name = "bandit";
      version = "1.3.0";

      src = fetchHex {
        pkg = "bandit";
        version = "${version}";
        sha256 = "bda37d6c614d74778a5dc43b8bcdc3245cd30619eab0342f58042f968f2165da";
      };

      beamDeps = [ hpax plug telemetry thousand_island websock ];
    };

    combine = buildMix rec {
      name = "combine";
      version = "0.10.0";

      src = fetchHex {
        pkg = "combine";
        version = "${version}";
        sha256 = "1b1dbc1790073076580d0d1d64e42eae2366583e7aecd455d1215b0d16f2451b";
      };

      beamDeps = [];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "0.1.2";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "2c87843d5a23f5f16748ebe77969880e29809580efdaccd615cd3bed628a8c13";
      };

      beamDeps = [];
    };

    ip = buildMix rec {
      name = "ip";
      version = "2.0.3";

      src = fetchHex {
        pkg = "ip";
        version = "${version}";
        sha256 = "19fa2f9c6f5cb288ca2192499888bd96f88af3564eaa7bbcfc1231ffdc5df8c2";
      };

      beamDeps = [];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.1";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "fbb01ecdfd565b56261302f7e1fcc27c4fb8f32d56eab74db621fc154604a7a1";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.5";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "da0d64a365c45bc9935cc5c8a7fc5e49a0e0f9932a761c55d6c52b142780a05c";
      };

      beamDeps = [];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.15.3";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "cc4365a3c010a56af402e0809208873d113e9c38c401cabd88027ef4f5c01fd2";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "2.0.0";

      src = fetchHex {
        pkg = "plug_crypto";
        version = "${version}";
        sha256 = "53695bae57cc4e54566d993eb01074e4d894b65a3766f1c43e2c61a1b0f45ea9";
      };

      beamDeps = [];
    };

    remote_ip = buildMix rec {
      name = "remote_ip";
      version = "1.1.0";

      src = fetchHex {
        pkg = "remote_ip";
        version = "${version}";
        sha256 = "616ffdf66aaad6a72fc546dabf42eed87e2a99e97b09cbd92b10cc180d02ed74";
      };

      beamDeps = [ combine plug ];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "dad9ce9d8effc621708f99eac538ef1cbe05d6a874dd741de2e689c47feafed5";
      };

      beamDeps = [];
    };

    thousand_island = buildMix rec {
      name = "thousand_island";
      version = "1.3.5";

      src = fetchHex {
        pkg = "thousand_island";
        version = "${version}";
        sha256 = "2be6954916fdfe4756af3239fb6b6d75d0b8063b5df03ba76fd8a4c87849e180";
      };

      beamDeps = [ telemetry ];
    };

    websock = buildMix rec {
      name = "websock";
      version = "0.5.3";

      src = fetchHex {
        pkg = "websock";
        version = "${version}";
        sha256 = "6105453d7fac22c712ad66fab1d45abdf049868f253cf719b625151460b8b453";
      };

      beamDeps = [];
    };

    zoneinfo = buildMix rec {
      name = "zoneinfo";
      version = "0.1.8";

      src = fetchHex {
        pkg = "zoneinfo";
        version = "${version}";
        sha256 = "3999755971bbf85f0c8c75a724be560199bb63406660585849f0eb680e2333f7";
      };

      beamDeps = [];
    };
  };
in self

