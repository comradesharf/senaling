extern crate cbindgen;

use anyhow::{Context, Result};
use std::env;
use std::path::Path;

fn main() -> Result<()> {
    let manifest_dir =
        env::var("CARGO_MANIFEST_DIR").with_context(|| "Unable to get CARGO_MANIFEST_DIR")?;

    cbindgen::Builder::new()
        .with_crate(&manifest_dir)
        .with_config(cbindgen::Config::from_root_or_default(&manifest_dir))
        .generate()
        .with_context(|| "Unable to generate bindings")?
        .write_to_file(
            Path::new(&manifest_dir)
                .join("../../packages/SenalingCore/Sources/SenalingCoreFFI/senaling_coreFFI.h"),
        );

    print!("cargo:rerun-if-changed=src");

    Ok(())
}
