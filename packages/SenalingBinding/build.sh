#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR=$(cd "$(dirname "$0")"; pwd)

cd ../../

ROOT_DIR=$(cd "$(dirname "$0")"; pwd)

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_binding.a \
    "$SOURCE_DIR/Sources/SenalingBinding" \
    --swift-sources

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_binding.a \
    "$SOURCE_DIR/Sources/SenalingBindingFFI" \
    --headers

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_binding.a \
    "$SOURCE_DIR/Sources/SenalingBindingFFI" \
    --modulemap \
    --modulemap-filename module.modulemap \
    --module-name senaling_bindingFFI

cd "$SOURCE_DIR"

rm -rf "$SOURCE_DIR/Frameworks/SenalingBindingFFI.xcframework"

xcodebuild -create-xcframework \
  -library "$ROOT_DIR/target/debug/libsenaling_binding.a" \
  -headers "$SOURCE_DIR/Sources/SenalingBindingFFI" \
  -output "$SOURCE_DIR/Frameworks/SenalingBindingFFI.xcframework"
