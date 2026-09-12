pub mod signature_check;

#[cfg(feature = "headers")]
pub fn generate_headers() -> ::std::io::Result<()> {
    ::safer_ffi::headers::builder()
        .to_file("packages/SenalingCore/Sources/SenalingCoreFFI/senaling_ffi.h")?
        .generate()
}
