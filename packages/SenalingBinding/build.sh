#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR=$(cd "$(dirname "$0")"; pwd)

cd ../../

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_binding.dylib \
    "$SOURCE_DIR/Sources/SenalingBinding" \
    --swift-sources

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_binding.dylib \
    "$SOURCE_DIR/Sources/SenalingBindingFFI" \
    --headers

cargo run \
    -p uniffi-bindgen \
    --bin uniffi-bindgen-swift -- \
    ./target/debug/libsenaling_binding.dylib \
    "$SOURCE_DIR/Sources/SenalingBindingFFI" \
    --modulemap \
    --modulemap-filename module.modulemap \
    --module-name senaling_bindingFFI

cd "$SOURCE_DIR"

swift build
