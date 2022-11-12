#!/usr/bin/env bash

APPDIR="./target/fonky.AppDir"
ICON="./assets/icon.svg"
DESKTOP_FILE=""
SETUP_FOLDERS=(
    "/usr/lib/qt/qml"
    "/usr/lib/qt/qml/org/kde"
    "/usr/lib/qt/plugins/platforms"
    "/usr/lib/qt/plugins/styles"
    "/usr/lib/qt/plugins/iconengines"
    "/usr/include/qt"
)
COPY_FILES=(
    "/usr/lib/qt/plugins/platforms/libqxcb.so"
    "/usr/lib/qt/plugins/styles/breeze.so"
    "/usr/lib/qt/plugins/iconengines/libqsvgicon.so"
    "/usr/lib/qt/qml/Qt"
    "/usr/lib/qt/qml/QtQuick"
    "/usr/lib/qt/qml/QtQuick.2"
    "/usr/lib/qt/qml/QtWayland"
    "/usr/lib/qt/qml/QtGraphicalEffects"
    "/usr/lib/qt/qml/builtins.qmltypes"
    "/usr/lib/qt/qml/org/kde/kirigami.2"
    "/usr/lib/qt/qml/org/kde/qqc2desktopstyle"
    "/usr/lib/qt/qml/org/kde/sonnet"
    "/usr/include/qt/QtQuick"
    "/usr/include/qt/QtQuickControls2"
    "/usr/include/qt/QtQuickWidgets"
)
ENV_VARS=(
    "QT_THEME_OVERRIDE=breeze"
    "XDG_DATA_DIRS=/usr/local/share:/usr/share"
)

# Build and setup AppDir
cargo appimage

# Setup icon
rm "$APPDIR/icon.png"
cp "$ICON" "$APPDIR/icon.svg"

# Setup .env file
rm "$APPDIR/.env"
touch "$APPDIR/.env"
for e in "${ENV_VARS[@]}"; do
    echo "$e" >"$APPDIR/.env"
done

# Create directories
for f in "${SETUP_FOLDERS[@]}"; do
    mkdir -p "$APPDIR$f"
done

# Copy deps
for f in "${COPY_FILES[@]}"; do
    cp -R "$f" "$APPDIR$f" && echo "File/folder copied: $f"
done

# Delete pre-created and old AppImages
rm ./*.AppImage

# Create AppImage from AppDir
appimagetool "$APPDIR"
