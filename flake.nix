{
  description = "libtorch-nix";
  inputs.utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, utils, ... }: let
      mkOverlay = name: final: prev:
        let
          libtorch-suite = prev.callPackage ./libtorch { pkgs=prev; };
          libtorch = libtorch-suite.${name};
        in {
        c10 = libtorch;
        torch = libtorch;
        torch_cpu = libtorch;
        torch_cuda = libtorch;
      };
    in
    {
      overlays = {
        cpu              = mkOverlay "libtorch_cpu";
        cudatoolkit_10_2 = mkOverlay "libtorch_cudatoolkit_10_2";
        cudatoolkit_11_1 = mkOverlay "libtorch_cudatoolkit_11_1";
      };
    } // (utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };
        libtorchSrc = pkgs.callPackage ./libtorch { inherit pkgs; };
      in
      rec {
        packages = {
          inherit (libtorchSrc)
            libtorch_cpu
            libmklml
            libmklml_without_iomp5
          ;
        } // (pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (libtorchSrc)
            libtorch_cudatoolkit_11_1
            libtorch_cudatoolkit_10_2
          ;
        });
      }
    ));
}
