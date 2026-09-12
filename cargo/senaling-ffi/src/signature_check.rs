use safer_ffi::prelude::*;
use senaling_core::shared::signature_check::SignatureCheck;

#[ffi_export]
/// Returns an owned type name when `leading_bytes` matches a known signature.
///
/// The caller owns the returned string and must pass the result to
/// [`signature_check_result_free`] exactly once.
pub fn get_signature_check(
    leading_bytes: c_slice::Ref<'_, u8>,
) -> repr_c::TaggedOption<repr_c::String> {
    let signature_check =
        senaling_core::nes::signature_check::NesSignatureCheck::new(leading_bytes.to_vec());
    if !signature_check.check_signature() {
        return repr_c::TaggedOption::None;
    }

    repr_c::TaggedOption::Some(signature_check.type_name().into())
}

#[ffi_export]
/// Releases a result returned by [`get_signature_check`].
pub fn signature_check_result_free(result: repr_c::TaggedOption<repr_c::String>) {
    drop(result);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn returns_type_name_for_matching_signature() {
        let bytes = b"NES\x1aROM-DATA-HERE";

        let result = get_signature_check(bytes.as_slice().into());

        assert!(matches!(
            result,
            repr_c::TaggedOption::Some(ref type_name) if &**type_name == "NES"
        ));
    }

    #[test]
    fn returns_none_for_unknown_signature() {
        let bytes = b"UNKNOWN";

        let result = get_signature_check(bytes.as_slice().into());

        assert!(matches!(result, repr_c::TaggedOption::None));
    }
}
