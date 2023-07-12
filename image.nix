{ pkgs ? import <nixpkgs> {} }:
let
  packages = [
    pkgs.bash
    pkgs.libvlc
    pkgs.shadow
    pkgs.cacert
  ];
in
pkgs.dockerTools.buildImage {
  name = "oremi-player-base";
  tag = "latest";
  copyToRoot = packages;
  config = {
    Cmd = [ "${pkgs.bash}/bin/bash" ];
    User = "oremi";
    WorkingDir = "/home/oremi";
  };
  runAsRoot = ''
    ${pkgs.shadow}/bin/useradd -u 1000 -m -s ${pkgs.bash}/bin/bash oremi
  '';
}
