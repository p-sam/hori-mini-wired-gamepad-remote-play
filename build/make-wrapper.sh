#!/bin/bash
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.." || exit 1

if [ ! -f "$PROJECT_DIR/out/iohid_wrap.dylib" ]; then
    echo "Compiled lib not found" 1>&2
    exit 1
fi

APP_NAME="RemotePlayWrapper.app"
APP_PATH="$PROJECT_DIR/out/$APP_NAME"

rm -rf "$APP_PATH" &> /dev/null
cp -r "$PROJECT_DIR/wrapper_skel" "$APP_PATH" || exit 1
chmod a+x "$APP_PATH/Contents/MacOS/RemotePlayWrapper"
cp "$PROJECT_DIR/out/iohid_wrap.dylib" "$APP_PATH/Contents/Resources/iohid_wrap.dylib" || exit 1

echo "Wrapper created at '$APP_PATH'."
echo "You copy RemotePlay.app into the the Contents/Resources folder inside the wrapper. It will default to use the one installed in /Applications"
