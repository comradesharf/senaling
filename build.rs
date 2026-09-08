use std::env;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Tell Cargo to regenerate the header if any Rust source file changes
    println!("cargo:rerun-if-changed=src");

    let crate_dir = env::var("CARGO_MANIFEST_DIR")?;
    let package_name = env::var("CARGO_PKG_NAME")?;

    let output_file = PathBuf::from(&crate_dir).join(format!("include/{}.h", package_name));
    cbindgen::generate(&crate_dir)?.write_to_file(output_file);

    Ok(())
}
