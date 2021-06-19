{ pkgs ? import ../nix/nixpkgs.nix {} }:

with pkgs;

let
  libtorch_version = "1.9.0";
  libcxx-for-libtorch = if stdenv.hostPlatform.system == "x86_64-darwin" then libcxx else stdenv.cc.cc.lib;
  libmklml = opts: callPackage ./mklml.nix ({
  } // opts);
  callCpu = opts: callPackage ./generic.nix ({
    libcxx = libcxx-for-libtorch;
  } // opts);
  callGpu = opts: callPackage ./generic.nix ({
    libcxx = libcxx-for-libtorch;
  } // opts);
in
{
  libmklml = libmklml { useIomp5 = true; };
  libmklml_without_iomp5 = libmklml { useIomp5 = false; };
  libtorch_cpu = callCpu {
    version = libtorch_version;
    buildtype = "cpu";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        libtorch-cpu-linux
      else if stdenv.hostPlatform.system == "x86_64-darwin" then
        libtorch-cpu-macos
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  ${if stdenv.hostPlatform.system == "x86_64-darwin" then null else "libtorch_cudatoolkit_11_1"} = callGpu {
    version = "cu111-${libtorch_version}";
    buildtype = "cu111";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        libtorch-cu111-linux
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  ${if stdenv.hostPlatform.system == "x86_64-darwin" then null else "libtorch_cudatoolkit_10_2"} = callGpu {
    version = "cu102-${libtorch_version}";
    buildtype = "cu102";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        libtorch-cu102-linux
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
}
