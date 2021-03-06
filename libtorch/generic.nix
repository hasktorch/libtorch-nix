{ lib, fetchzip, autoreconfHook, gettext
, version ? "1.8", mkSrc, buildtype
, libcxx ? null
, stdenv
, unzip
}:

stdenv.mkDerivation rec {
  name = "libtorch-${version}";
  inherit version;

  src = mkSrc buildtype;
  libcxxPath  = libcxx.outPath;
  nativeBuildInputs  = [unzip];
  unpackCmd = ''
    ${unzip}/bin/unzip "$curSrc"
    sourceRoot=libtorch
  '';

  propagatedBuildInputs = if stdenv.isDarwin then [ libcxx ] else [];
  preFixup = lib.optionalString stdenv.isDarwin ''
    echo "-- before fixup --"
    for f in $(ls $out/lib/*.dylib); do
        otool -L $f
    done
    for f in $(ls $out/lib/*.dylib); do
      install_name_tool -id $out/lib/$(basename $f) $f || true
      for rpath in $(otool -L $f | grep rpath | awk '{print $1}');do
        install_name_tool -change $rpath $out/lib/$(basename $rpath) $f
      done
      if otool -L $f | grep /usr/lib/libc++ >& /dev/null ;then
        install_name_tool -change /usr/lib/libc++.1.dylib  $libcxxPath/lib/libc++.1.0.dylib $f
      fi
    done
    echo "-- after fixup --"
    for f in $(ls $out/lib/*.dylib); do
        otool -L $f
    done
  '';
  installPhase = ''
    mkdir $out
    if [ -d ./bin ] ; then
      cp -r {.,$out}/bin/
    fi
    cp -r {.,$out}/include/
    cp -r {.,$out}/lib/
    cp -r {.,$out}/share/
  '';

  dontStrip = true;

  meta = with lib; {
    description = "libtorch";
    homepage = https://pytorch.org/;
    license = licenses.bsd3;
    platforms = with platforms; linux ++ darwin;
  };
}
