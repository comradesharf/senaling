mod nes;
pub mod rom_file;
pub mod shared;

#[cfg(feature = "headers")]
pub fn generate_headers() -> ::std::io::Result<()> {
    ::safer_ffi::headers::builder()
        .to_file("packages/SenalingCore/Sources/SenalingCoreFFI/senaling_coreFFI.h")?
        .generate()
}
