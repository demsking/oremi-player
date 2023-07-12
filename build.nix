{ pkgs ? import <nixpkgs> {} }:
let
  packages = [
    pkgs.asio
    pkgs.wget
    pkgs.gnumake
    pkgs.gnutar
    pkgs.nlohmann_json
    pkgs.websocketpp
    pkgs.libvlc
    pkgs.bash
    pkgs.gzip
    pkgs.coreutils
    pkgs.gcc
  ];
in
pkgs.dockerTools.buildImage {
  name = "oremi-player-build";
  tag = "latest";
  copyToRoot = packages;
  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
  };
}
