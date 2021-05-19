{ pkgs ? import ../pin/nixpkgs.nix {} }:

with pkgs;

let
  libtorch_version = "1.8.1";
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
        fetchzip {
          # Source file is  "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-${libtorch_version}%2Bcpu.zip".
          # Nix can not use the url directly, because this link includes '%2B'.
          #url = "https://github.com/hasktorch/libtorch-binary-for-ci/releases/download/${libtorch_version}/cpu-libtorch-cxx11-abi-shared-with-deps-latest.zip";
          url = "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-${libtorch_version}%2Bcpu.zip";
          sha256 = "01wav5s98fch8q1inixs8xrlnbbmy3v90gxvh6hrbnyqb9qq4xy6";
        }
      else if stdenv.hostPlatform.system == "x86_64-darwin" then
        fetchzip {
          url = "https://download.pytorch.org/libtorch/cpu/libtorch-macos-${libtorch_version}.zip";
          sha256 = "0fw3i7sa6n2h2hhiq4fig9hldix44fbnvybkcb1cijg5kivjg20m";
        }
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  ${if stdenv.hostPlatform.system == "x86_64-darwin" then null else "libtorch_cudatoolkit_11_1"} = callGpu {
    version = "cu111-${libtorch_version}";
    buildtype = "cu111";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        fetchzip {
          #url = "https://github.com/hasktorch/libtorch-binary-for-ci/releases/download/${libtorch_version}/cu111-libtorch-cxx11-abi-shared-with-deps-latest.zip";
          url = "https://download.pytorch.org/libtorch/cu111/libtorch-cxx11-abi-shared-with-deps-${libtorch_version}%2Bcu111.zip";
          sha256 = "17cvi01jkqadc0gzjdssrp5z5m71qh8wnhiv0x38y3r79mdr6vsm";
        }
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
  ${if stdenv.hostPlatform.system == "x86_64-darwin" then null else "libtorch_cudatoolkit_10_2"} = callGpu {
    version = "cu102-${libtorch_version}";
    buildtype = "cu102";
    mkSrc = buildtype:
      if stdenv.hostPlatform.system == "x86_64-linux" then
        fetchzip {
          url = "https://download.pytorch.org/libtorch/cu102/libtorch-cxx11-abi-shared-with-deps-${libtorch_version}%2Bcu102.zip";
          sha256 = "0s7z407r83xjc1kfnlmf5pgnyfkjik9vwxcxiz67xbyscdj1bggn";
        }
      else throw "missing url for platform ${stdenv.hostPlatform.system}";
  };
}
