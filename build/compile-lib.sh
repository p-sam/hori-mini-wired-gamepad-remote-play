#!/bin/bash
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.." || exit 1

mkdir -p "$PROJECT_DIR/out"

exec clang -dynamiclib -std=gnu99 "$PROJECT_DIR/iohid_wrap.m" -current_version 1.0 -compatibility_version 1.0 -lobjc -framework Foundation -framework AppKit -framework CoreFoundation -o "$PROJECT_DIR/out/iohid_wrap.dylib"
