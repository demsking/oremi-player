{
  description = "Oremi Player";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        devShell = with pkgs; mkShell rec {
          EDITOR = "vim";
          buildInputs = [
            # devtools
            gnumake
            pkgs.snapcast

            # dependencies
            asio
            libvlc
            nlohmann_json
            websocketpp

            # tmux
            tmuxinator
            tmux
            gitmux
            git
          ];
          shellHook = ''
            export PATH=${pkgs.snapcast}/bin:$PATH
            export HEADER_INCLUDE_PATH=${pkgs.websocketpp}/include:${pkgs.nlohmann_json}/include:${pkgs.libvlc}/include
          '';
        };
    });
}
