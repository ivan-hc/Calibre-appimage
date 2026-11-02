#!/bin/sh

APP=calibre

ARCH="x86_64"

# DEPENDENCIES

dependencies="tar"
for d in $dependencies; do
	if ! command -v "$d" 1>/dev/null; then
		echo "ERROR: missing command \"d\", install the above and retry" && exit 1
	fi
done

_appimagetool() {
	if ! test -f ./appimagetool; then
		wget -q https://github.com/pkgforge-dev/appimagetool/releases/latest/download/appimagetool-x86_64-linux -O appimagetool
		chmod a+x ./appimagetool
	fi
	./appimagetool "$@"
}

DOWNLOAD_PAGE=$(curl -Ls https://download.calibre-ebook.com/preview/ | tr '">< ' '\n' | grep -i x86_64 | tail -1)
DOWNLOAD_URL="https://download.calibre-ebook.com/preview/$DOWNLOAD_PAGE"
VERSION=$(echo "$DOWNLOAD_URL" | tr '/-' '\n' | grep "^[0-9]")
[ ! -f "$APP.txz" ] && curl -#Lo "$APP.txz" "$DOWNLOAD_URL"
mkdir -p "$APP".AppDir || exit 1

# Extract the package
tar fx ./*txz* -C ./"$APP".AppDir/ || exit 1

_appimage_basics() {
	# Launcher
	cat <<-HEREDOC >> ./"$APP".AppDir/"$APP".desktop
	[Desktop Entry]
	Categories=Office;
	Comment[en_US]=E-book library management: Convert, view, share, catalogue all your e-books
	Comment=E-book library management: Convert, view, share, catalogue all your e-books
	Exec=AppRun
	GenericName[en_US]=E-book library management
	GenericName=E-book library management
	Icon=calibre
	MimeType=application/vnd.openxmlformats-officedocument.wordprocessingml.document;image/vnd.djvu;application/x-mobi8-ebook;application/x-cbr;text/fb2+xml;application/pdf;application/x-cbc;application/vnd.ms-word.document.macroenabled.12;text/rtf;application/epub+zip;application/x-cbz;text/plain;application/x-sony-bbeb;application/oebps-package+xml;application/x-cb7;application/x-mobipocket-ebook;application/ereader;text/html;text/x-markdown;application/xhtml+xml;application/vnd.oasis.opendocument.text;application/x-mobipocket-subscription;x-scheme-handler/calibre;
	Name=Calibre (preview)
	Type=Application
	X-DBUS-ServiceName=
	X-DBUS-StartupType=
	X-KDE-SubstituteUID=false
	X-KDE-Username=
	HEREDOC

	# Icon
	cp ./"$APP".AppDir/resources/content-server/"$APP".png ./"$APP".AppDir/"$APP".png
	cp ./"$APP".AppDir/"$APP".png ./"$APP".AppDir/.DirIcon

	# AppRun
	printf '#!/bin/sh\nHERE="$(dirname "$(readlink -f "${0}")")"\nexec "${HERE}"/%b "$@"' "$APP" > ./"$APP".AppDir/AppRun && chmod a+x ./"$APP".AppDir/AppRun
}

_appimage_basics

#############################################################################
#	CREATE THE APPIMAGE
#############################################################################

APPNAME="Calibre"
REPO="Calibre-appimage"
TAG="continuous-preview"
VERSION="$VERSION"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

APPIMAGE_ARCH=x86_64 VERSION="$VERSION" _appimagetool \
	-u "$UPINFO" \
	-n "$APPNAME"-preview_"$VERSION"-x86_64.AppImage \
	./"$APP".AppDir || exit 1

if ! test -f ./*.AppImage; then
	echo "No AppImage available."; exit 1
fi
