#!/bin/bash
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.." || exit 1

DYLD_FORCE_FLAT_NAMESPACE=1 DYLD_INSERT_LIBRARIES="$PROJECT_DIR/out/iohid_wrap.dylib" /Applications/RemotePlay.app/Contents/MacOS/RemotePlay