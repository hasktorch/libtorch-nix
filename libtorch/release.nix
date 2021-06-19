{ sources ? import ../nix/sources.nix {}
, pkgs ? sources.nixpkgs
}:

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
  libmklml = libmklml { useIomp5 = true; inherit lib;};
  libmklml_without_iomp5 = libmklml { useIomp5 = false; inherit lib;};
  libtorch_cpu = callCpu {
    version = libtorch_version;
    buildtype = "cpu";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        sources.libtorch-cpu-linux
      else if stdenv.hostPlatform.system == "x86_64-darwin" then
        sources.libtorch-cpu-macos
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  ${if stdenv.hostPlatform.system == "x86_64-darwin" then null else "libtorch_cudatoolkit_11_1"} = callGpu {
    version = "cu111-${libtorch_version}";
    buildtype = "cu111";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        sources.libtorch-cu111-linux
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  ${if stdenv.hostPlatform.system == "x86_64-darwin" then null else "libtorch_cudatoolkit_10_2"} = callGpu {
    version = "cu102-${libtorch_version}";
    buildtype = "cu102";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        sources.libtorch-cu102-linux
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
}
