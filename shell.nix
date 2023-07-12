{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.asio
    pkgs.libvlc
    pkgs.gnumake
    pkgs.nlohmann_json
    pkgs.websocketpp
  ];
  shellHook = ''
    export HEADER_INCLUDE_PATH=${pkgs.websocketpp}/include:${pkgs.nlohmann_json}/include:${pkgs.libvlc}/include
  '';
}
