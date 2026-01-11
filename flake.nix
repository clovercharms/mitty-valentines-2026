{
  description = "Godot 4 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Libraries required by Godot at runtime
        runtimeLibs = with pkgs; [
          libGL
          vulkan-loader
          xorg.libX11
          xorg.libXcursor
          xorg.libXext
          xorg.libXi
          xorg.libXrandr
          xorg.libXinerama
          libpulseaudio
          alsa-lib
          udev
          fontconfig
          dbus
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            godot_4 
            git
            scons
            pkg-config
            gcc
          ] ++ runtimeLibs;

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH"
            
            echo "--- Godot 4 Dev Environment Loaded ---"
            godot --version
            echo "run engine with godot -e"
          '';
        };
      });
}
