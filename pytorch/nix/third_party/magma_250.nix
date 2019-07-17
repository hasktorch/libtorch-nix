{ stdenv, fetchurl, cmake, gfortran, cudatoolkit, libpthreadstubs, liblapack, mklSupport ? false, mkl ? null }:

assert !mklSupport || mkl != null;

with stdenv.lib;

let version = "2.4.0";

in stdenv.mkDerivation {
  name = "magma-${version}";
  src = fetchurl {
    url = "https://icl.cs.utk.edu/projectsfiles/magma/downloads/magma-${version}.tar.gz";
    sha256 = "0kws3ygidlc07xbldbvnz45h2xl4aznv9xd6r0lzs1al56qkkf2f";
    name = "magma-${version}.tar.gz";
  };

  buildInputs = [ gfortran cudatoolkit libpthreadstubs liblapack cmake ]
    ++ optionals mklSupport [ mkl ];

  preConfigure = ''
    export CC=${cudatoolkit.cc}/bin/gcc CXX=${cudatoolkit.cc}/bin/g++
  '';

  doCheck = false;
  #checkTarget = "tests";

  enableParallelBuilding=true;

  # MAGMA's default CMake setup does not care about installation. So we copy files directly.
  installPhase = ''
    mkdir -p $out
    mkdir -p $out/include
    mkdir -p $out/lib
    mkdir -p $out/lib/pkgconfig
    cp -a ../include/*.h $out/include
    #cp -a sparse-iter/include/*.h $out/include
    cp -a lib/*.a $out/lib
    cat ../lib/pkgconfig/magma.pc.in                   | \
    sed -e s:@INSTALL_PREFIX@:"$out":          | \
    sed -e s:@CFLAGS@:"-I$out/include":    | \
    sed -e s:@LIBS@:"-L$out/lib -lmagma -lmagma_sparse": | \
    sed -e s:@MAGMA_REQUIRED@::                       \
        > $out/lib/pkgconfig/magma.pc
  '';

  meta = with stdenv.lib; {
    description = "Matrix Algebra on GPU and Multicore Architectures";
    license = licenses.bsd3;
    homepage = http://icl.cs.utk.edu/magma/index.html;
    platforms = platforms.unix;
    maintainers = with maintainers; [ ianwookim ];
  };
}