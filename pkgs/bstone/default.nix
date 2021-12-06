{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, makeDesktopItem
, cmake
, SDL2
, enableAOG ? false
, enableAOGSW ? false
, enablePS ? false
}:
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

    buildInputs = [ cmake makeWrapper SDL2fix  ];

    cmakeFlags = [ 
      #"DCUDA_LIB=/usr/local/cuda/lib64/stubs/libcuda.so"
      #"DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda"
      #"-DSDL2_DIR=${SDL2}/lib"
    ];

    desktopAog = makeDesktopItem {
      name = "bstone-aog";
      exec = "bstone-aog";
      # icon = ""; # No icon right now
      comment = "Play Blake Stone: Aliens of Gold with the bstone source port";
      desktopName = "Blake Stone: Aliens of Gold";
      genericName = "Blake Stone: Aliens of Gold via bstone";
      categories = "Game;Shooter;";
    };

    desktopAogSw = makeDesktopItem {
      name = "bstone-aog-sw";
      exec = "bstone-aog-sw";
      # icon = ""; # No icon right now
      comment = "Play Blake Stone: Aliens of Gold (Shareware) with the bstone source port";
      desktopName = "Blake Stone: Aliens of Gold (Shareware)";
      genericName = "Blake Stone: Aliens of Gold (Shareware) via bstone";
      categories = "Game;Shooter;";
    };

    desktopPs = makeDesktopItem {
      name = "bstone-ps";
      exec = "bstone-ps";
      # icon = ""; # No icon right now
      comment = "Play Blake Stone: Planet Strike with the bstone source port";
      desktopName = "Blake Stone: Planet Strike";
      genericName = "Blake Stone: Planet Strike via bstone";
      categories = "Game;Shooter;";
    };

    postInstall = ''
      rm $out/*.txt
      mkdir -p $out/bin
      mv $out/${pname} $out/bin/
      mkdir -p $out/share/applications
    '' 
      + lib.optionalString enableAOG ''
        cp ${desktopAog}/share/applications/* $out/share/applications
      '' + lib.optionalString enableAOGSW ''
        cp ${desktopAogSw}/share/applications/* $out/share/applications
      '' + lib.optionalString enablePS ''
        cp ${desktopPs}/share/applications/* $out/share/applications
      '';

    postFixup = lib.optionalString enableAOG ''
      makeWrapper $out/bin/${pname} $out/bin/${pname}-aog\
        --add-flags "--aog" \
        --add-flags ${lib.escapeShellArg "--data_dir=$HOME/.local/share/bstone/aog"} \
        --add-flags ${lib.escapeShellArg "--profile_dir=$HOME/.local/share/bstone"}
      '' + lib.optionalString enableAOGSW ''
      makeWrapper $out/bin/${pname} $out/bin/${pname}-aog-sw\
        --add-flags "--aog_sw" \
        --add-flags ${lib.escapeShellArg "--data_dir=$HOME/.local/share/bstone/aog-sw"} \
        --add-flags ${lib.escapeShellArg "--profile_dir=$HOME/.local/share/bstone"}
      '' + lib.optionalString enablePS ''
      makeWrapper $out/bin/${pname} $out/bin/${pname}-aog-sw\
        --add-flags "--ps" \
        --add-flags ${lib.escapeShellArg "--data_dir=$HOME/.local/share/bstone/ps"} \
        --add-flags ${lib.escapeShellArg "--profile_dir=$HOME/.local/share/bstone"}
    '';

    meta = with lib; {
      # broken = true; # Don't run this in CI for now
      homepage = "https://github.com/bibendovsky/bstone";
      description = "Unofficial source port for Blake Stone series (Aliens Of Gold and Planet Strike)";
      platforms = platforms.unix;
      maintainers = with maintainers; [ ];
      license = licenses.gpl2;  
    };

}
