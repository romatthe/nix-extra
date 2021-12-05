{ stdenv, lib, fetchFromGitHub, makeDesktopItem, SDL, SDL_net, SDL_sound, libGLU, libGL, libpng, graphicsmagick, autoreconfHook }:

stdenv.mkDerivation rec {
  pname = "dosbox-gridc";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = "hiddenasbestos";
    repo = "dosbox-gridc";
    rev = "GC-v${version}";
    sha256 = "9a3Cl3yN2Vco20ocFA9Xea1cw50tC/3339MH1JlvpFg=";
  };

  hardeningDisable = [ "format" ];

  buildInputs = [ SDL SDL_net SDL_sound libGLU libGL libpng ];

  nativeBuildInputs = [ autoreconfHook graphicsmagick ];

  configureFlags = lib.optional stdenv.isDarwin "--disable-sdltest";

  desktopItem = makeDesktopItem {
    name = "dosbox-gridc";
    exec = "dosbox-gridc";
    icon = "dosbox-gridc";
    comment = "x86 emulator with internal DOS for Grid Cartographer";
    desktopName = "DOSBox GridC";
    genericName = "DOS emulator for Grid Cartographer";
    categories = "Emulator;";
  };

  postInstall = ''
     mkdir -p $out/share/applications
     cp ${desktopItem}/share/applications/* $out/share/applications
     mkdir -p $out/share/icons/hicolor/256x256/apps
     gm convert src/dosbox.ico $out/share/icons/hicolor/256x256/apps/dosbox-gridc.png
  '';

  postFixup = ''
    # Rename binary, but don't wrap or alias to regular `dosbox`, as this is not a general purpose
    # dosbox package, and we don't want to use it by default. We only want to specifically use it
    # Grid Cartographer
    mv $out/bin/dosbox $out/bin/${pname}
    mv $out/share/man/man1/dosbox.1.gz $out/share/man/man1/${pname}.1.gz
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "http://www.dosbox.com/";
    description = "Port of DOSBox with Game Link features for Grid Cartographer";
    platforms = platforms.unix;
    maintainers = with maintainers; [ romatthe ];
    license = licenses.gpl2;
  };
}