{
  nixpkgs,
  flake-utils,
  ...
}: args@{
  extraInputs ? _: [],
  ...
}:
let
  opamEnv = pkgs:
  import ./opam.nix ({ inherit pkgs; } // args);

  shell = pkgs:
  pkgs.mkShell {
    buildInputs = with pkgs; extraInputs pkgs ++ [
      autoconf
      automake
      bazel_4
      gcc
      libtool
      m4
      opam
      pkg-config
    ];
    inherit (opamEnv pkgs) shellHook;
  };

  main = system: 
  let
    pkgs = import nixpkgs { inherit system; };

    opam = opamEnv pkgs;

    installDeps = pkgs.writeScript "install-opam-deps" ''
      nix develop -c ${opam.installDeps}
    '';

    installDepsEach = pkgs.writeScript "install-opam-deps-each" ''
      nix develop -c ${opam.installDepsEach}
    '';
  in rec {
    apps = {
      install = {
        type = "app";
        program = "${installDeps}";
      };
      installEach = {
        type = "app";
        program = "${installDepsEach}";
      };
    };
    defaultApp = apps.install;
    devShell = shell pkgs;
  };
in {
  inherit opamEnv shell main;
  systems = flake-utils.lib.eachDefaultSystem main;
}
