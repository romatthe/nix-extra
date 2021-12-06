{ stdenv, lib, fetchFromGitHub, cmake, SDL2 }:
let
  # The SDL2 package is weird in that it does not output any libSDL2main.a files, which breaks
  # cmake builds that explicitly look for it.
  # See issue: https://github.com/NixOS/nixpkgs/issues/98242
  # See tempory fix: https://github.com/NixOS/nixpkgs/issues/146759
  SDL2fix = SDL2.overrideAttrs (old: {
    postInstall = ''
      moveToOutput lib/libSDL2main.a "$dev"
      if [ "$dontDisableStatic" -eq "1" ]; then
        rm $out/lib/*.la
      else
        rm $out/lib/*.a
      fi
      moveToOutput bin/sdl2-config "$dev"
      cp $dev/lib/libSDL2main.a $out/lib/
    '';
  });
in
  stdenv.mkDerivation rec {
    pname = "bstone";
    version = "1.2.11";

    src = fetchFromGitHub {
      owner = "bibendovsky";
      repo = "${pname}";
      rev = "v${version}";
      sha256 = "Uwxa0XGmX7iX5v+3iBYBmXDwokf9u0pHHdCdEfEMH+I=";
    };

    buildInputs = [ cmake SDL2fix  ];

    cmakeFlags = [ 
      #"DCUDA_LIB=/usr/local/cuda/lib64/stubs/libcuda.so"
      #"DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda"
      #"-DSDL2_DIR=${SDL2}/lib"
    ];

    meta = with lib; {
      broken = true; # Don't run this in CI for now
      homepage = "https://github.com/bibendovsky/bstone";
      description = "Unofficial source port for Blake Stone series (Aliens Of Gold and Planet Strike)";
      platforms = platforms.unix;
      maintainers = with maintainers; [ ];
      license = licenses.gpl2;  
    };
}
