{ stdenv, lib, fetchsvn, makeWrapper, makeDesktopItem, cmake, mesa, xorg, libGLU, libGL, openal }:

let
  pname = "tdm";
  version = "2.09b";

  desktop = makeDesktopItem {
    desktopName = pname;
    name = pname;
    exec = "@out@/bin/${pname}";
    icon = pname;
    terminal = "false";
    comment = "The Dark Mod - stealth FPS inspired by the Thief series";
    type = "Application";
    categories = "Game;";
    genericName = pname;
    fileValidation = false;
  };
in stdenv.mkDerivation {
  name = "${pname}";
  version = "${version}";

  src = fetchsvn {
    url = "https://svn.thedarkmod.com/publicsvn/darkmod_src/tags/${version}";
    rev = "9715";
    sha256 = "1a3j38wfnb47r6ck5b0sp0md36qrzdyz7knz8fp34wwwvhvw3w6b";
  };

  #  sudo apt-get install mesa-common-dev          //no such file: "Gl/gl.h", <=2.07
  #  sudo apt-get install libxxf86vm-dev           //no such file: "X11/extensions/xf86vmode.h"
  #  sudo apt-get install libopenal-dev            //no such file: "AL/al.h"
  #  sudo apt-get install libxext-dev              //no such file: "X11/extensions/Xext.h"

  nativeBuildInputs = [ cmake ];

  buildInputs = [ mesa openal libGL libGLU xorg.libX11 xorg.libXext xorg.libXxf86vm ];

  cmakeFlags = [ "-DCOPY_EXE=OFF" "-DCMAKE_CXX_FLAGS=-Wno-error=format-security" ];
  # NIX_CFLAGS_COMPILE = "-Wno-error=format-security";

  # unpackPhase = ''
  #   7z x $src
  # '';

  # I'm pretty sure there's a better way to build 2 targets than a random hook
  #   preBuild = ''
  #     pushd tdm_update
  #     scons BUILD=release TARGET_ARCH=x64
  #     install -Dm755 bin/tdm_update.linux64 $out/share/libexec/tdm_update.linux
  #     popd
  #   '';

  installPhase = ''
    ls -lah
    mkdir -p $out/bin
    mv thedarkmod.x64 $out/bin/the-dark-mod
  '';

  # why oh why can it find ld but not strip?
  # postPatch = ''
  #   # This adds math.h needed for math::floor
  #   sed -i 's|#include "Util.h"|#include "Util.h"\n#include <math.h>|' tdm_update/ConsoleUpdater.cpp
  # '';

    installPhase = ''
      runHook preInstall
      #install -Dm644 ${desktop}/share/applications/${pname}.desktop $out/share/applications/${pname}.desktop
      #substituteInPlace $out/share/applications/${pname}.desktop --subst-var out
      #install -Dm755 thedarkmod.x64 $out/share/libexec/tdm
      # The package doesn't install assets, these get installed by running tdm_update.linux
      # Provide a script that runs tdm_update.linux on first launch
      zenity --info --no-wrap --text="R.E.L.I.V.E. can't find the install directory of Abe's Exoddus.\nPlease select the folder containing the .lvl files."
      install -Dm755 <(cat <<'EOF'
  #!/bin/sh
  set -e
  DIR="$HOME/.local/share/tdm"
  mkdir -p "$DIR"
  cd "$DIR"
  exec "PKGDIR/share/libexec/tdm_update.linux" --noselfupdate
  EOF
      ) $out/bin/tdm_update
      install -Dm755 <(cat <<'EOF'
  #!/bin/sh
  set -e
  DIR="$HOME/.local/share/tdm"
  if [ ! -d "$DIR" ]; then
    echo "Please run tdm_update to (re)download game data"
  else
    cd "$DIR"
    exec "PKGDIR/share/libexec/tdm"
  fi
  EOF
      ) $out/bin/tdm
      sed -i "s!PKGDIR!$out!g" $out/bin/tdm_update
      sed -i "s!PKGDIR!$out!g" $out/bin/tdm
      runHook postInstall
    '';

  #   postInstall = ''
  #     wrapProgram $out/bin/tdm --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL libGLU ]}
  #   '';

  enableParallelBuilding = true;

  meta = with lib; {
    broken = true;
    description = "The Dark Mod - stealth FPS inspired by the Thief series";
    homepage = "http://www.thedarkmod.com";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
    platforms = with platforms;
      [
        "x86_64-linux"
      ]; # tdm also supports x86, but I don't have a x86 install at hand to test.
  };
}
