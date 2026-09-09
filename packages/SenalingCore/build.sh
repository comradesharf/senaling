#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR=$(cd "$(dirname "$0")"; pwd)

cd ../../

ROOT_DIR=$(cd "$(dirname "$0")"; pwd)

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_core.a \
    "$SOURCE_DIR/Sources/SenalingCore" \
    --swift-sources

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_core.a \
    "$SOURCE_DIR/Sources/SenalingCoreFFI" \
    --headers

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_core.a \
    "$SOURCE_DIR/Sources/SenalingCoreFFI" \
    --modulemap \
    --modulemap-filename module.modulemap \
    --module-name senaling_coreFFI

cd "$SOURCE_DIR"

rm -rf "$SOURCE_DIR/Frameworks/SenalingCoreFFI.xcframework"

xcodebuild -create-xcframework \
  -library "$ROOT_DIR/target/debug/libsenaling_core.a" \
  -headers "$SOURCE_DIR/Sources/SenalingCoreFFI" \
  -output "$SOURCE_DIR/Frameworks/SenalingCoreFFI.xcframework"
