use safer_ffi::prelude::*;
use senaling_core::shared::signature_check::SignatureCheck;

#[ffi_export]
pub fn get_signature_check(leading_bytes: c_slice::Ref<'_, u8>) {
    let signature_check =
        senaling_core::nes::signature_check::NesSignatureCheck::new(leading_bytes.to_vec());
    if signature_check.check_signature() {
        println!(
            "Signature check passed for type: {}",
            signature_check.type_name()
        );
    } else {
        println!(
            "Signature check failed for type: {}",
            signature_check.type_name()
        );
    }
}
