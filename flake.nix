{
  description = "Python with uv package management";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs-python.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
    ];
  };

  outputs = { nixpkgs, nixpkgs-python, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; }; 
        pythonVersion = "3.13";
      in
      {
        devShells.default = with pkgs; mkShell {
          packages = [
            nixpkgs-python.packages.${system}.${pythonVersion}
            uv
          ];

          # Native library dependencies
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            # Numpy dependencies
            stdenv.cc.cc
            zlib

            # PySide6 dependencies; for matplotlib qtagg backend
            zstd
            dbus
            libGL
            glib
            fontconfig
            freetype
            xorg.libX11
            xorg.libxcb
            xorg.xcbutilwm
            xorg.xcbutilimage
            xorg.xcbutil
            xorg.xcbutilkeysyms
            xorg.xcbutilrenderutil
            xcb-util-cursor
            libxkbcommon

            # CUDA and nvidia driver for PyTorch/Tensorflow
            cudatoolkit cudaPackages.cudnn linuxPackages.nvidia_x11
          ];

          # For matplotlib qtagg backend
          QT_QPA_PLATFORM = "xcb";


          # Force use of keras 2 instead of keras 3 for compatibility with Cascade
          TF_USE_LEGACY_KERAS = 1;

          # Make tensorflow be quiet about CPU optimization
          TF_CPP_MIN_LOG_LEVEL = 2;

          shellHook = ''
            if [ ! -f ./.venv/bin/activate ]; then
              uv sync
            fi
            source ./.venv/bin/activate
          '';
        };
      }
    );
}
