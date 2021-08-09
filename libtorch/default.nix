{ pkgs, ... }:
with pkgs;

let
  mkUrl = build: os: let url = "https://download.pytorch.org/libtorch/"; in
    if os == "linux"
    then "${url}${build}/libtorch-cxx11-abi-shared-with-deps-${libtorch_version}%2B${build}.zip"
    else if os == "macos" && build == "cpu" then "${url}cpu/libtorch-macos-${libtorch_version}.zip"
    else throw "bad build config";

  fetcher = build: os: let
    name =  "libtorch-${build}-${os}";
    sha256 = lib.strings.removeSuffix "\n" (builtins.readFile (./sha + "/${name}"));
    url = mkUrl build os;
  in pkgs.fetchzip {inherit url sha256; name = name + "-" + libtorch_version; };

  libtorch-cpu-macos   = fetcher "cpu"   "macos";
  libtorch-cpu-linux   = fetcher "cpu"   "linux";
  libtorch-cu102-linux = fetcher "cu102" "linux";
  libtorch-cu111-linux = fetcher "cu111" "linux";

  libtorch_version = "1.9.0";
  libcxx-for-libtorch = if stdenv.hostPlatform.system == "x86_64-darwin" then libcxx else stdenv.cc.cc.lib;
  libmklml = opts: callPackage ./mklml.nix ({} // opts);
  callCpu = opts: callPackage ./generic.nix ({libcxx = libcxx-for-libtorch;} // opts);
  callGpu = opts: callPackage ./generic.nix ({libcxx = libcxx-for-libtorch;} // opts);
in
{
  libmklml = libmklml { useIomp5 = true; inherit lib;};
  libmklml_without_iomp5 = libmklml { useIomp5 = false; inherit lib;};

  libtorch_cpu = callCpu {
    version = libtorch_version;
    buildtype = "cpu";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then libtorch-cpu-linux
      else if stdenv.hostPlatform.system == "x86_64-darwin" then libtorch-cpu-macos
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
} // lib.optionalAttrs (stdenv.hostPlatform.system == "x86_64-linux") {
  libtorch_cudatoolkit_11_1 = callGpu {
    version = "cu111-${libtorch_version}";
    buildtype = "cu111";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then libtorch-cu111-linux
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  libtorch_cudatoolkit_10_2 = callGpu {
    version = "cu102-${libtorch_version}";
    buildtype = "cu102";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then libtorch-cu102-linux
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
}
