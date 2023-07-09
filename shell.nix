{ pkgs ? import <nixpkgs> {} }:

let
  envDir = "$(pwd)/venv";
in

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.bash
    pkgs.gnumake
    pkgs.checkmake
    pkgs.ruff
    pkgs.poetry
    pkgs.pre-commit
    pkgs.python311
    pkgs.python311Packages.pylint
    pkgs.python311Packages.virtualenv
    pkgs.python311Packages.pyupgrade
    pkgs.python311Packages.websockets
    pkgs.python311Packages.pre-commit-hooks
  ];
  shellHook = ''
    export VIRTUAL_ENV_DISABLE_PROMPT=true

    virtualenv `basename ${envDir}`

    export PIP_PREFIX=${envDir}
    export PYTHONUSERBASE=${envDir}
    export PYTHON_SITE_PACKAGES=$PIP_PREFIX/${pkgs.python310.sitePackages}
    export PYTHONPATH="$PYTHON_SITE_PACKAGES:$PYTHONPATH"
    export PATH="$PIP_PREFIX/bin:${pkgs.ruff}/bin:$PATH"
    unset SOURCE_DATE_EPOCH

    source ${envDir}/bin/activate
    pre-commit install
  '';
  TMPDIR = "/tmp";
}
