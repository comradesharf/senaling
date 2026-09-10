use ::safer_ffi::prelude::*;
use std::rc::Rc;

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct RomFileMetadata {
    pub path: repr_c::String,
    pub leading_bytes: repr_c::Vec<u8>,
}

pub trait RomFile {
    fn metadata(&self) -> &RomFileMetadata;

    fn signatures(&self) -> &[&[u8]];

    fn max_signature_length(&self) -> usize {
        self.signatures()
            .iter()
            .map(|sig| sig.len())
            .max()
            .unwrap_or(0)
    }

    fn check_signature(&self) -> bool {
        self.metadata().leading_bytes.len() >= self.max_signature_length()
            && self
                .signatures()
                .iter()
                .any(|&sig| &self.metadata().leading_bytes[0..sig.len()] == sig)
    }
}

#[derive_ReprC]
#[repr(opaque)]
pub struct RomFileHandle {
    pub rom_file: Rc<dyn 'static + RomFile>,
}

#[cfg(test)]
mod tests {
    use super::*;

    struct TestRomFile {
        metadata: RomFileMetadata,
    }

    impl RomFile for TestRomFile {
        fn metadata(&self) -> &RomFileMetadata {
            &self.metadata
        }
        fn signatures(&self) -> &[&[u8]] {
            &[b"TEST"]
        }
    }

    #[test]
    fn test_check_signature() {
        let rom_file = TestRomFile {
            metadata: RomFileMetadata {
                path: "test_path".into(),
                leading_bytes: repr_c::Vec::from(b"TEST LEADING".to_vec()),
            },
        };
        assert_eq!(rom_file.check_signature(), true);

        let rom_file = TestRomFile {
            metadata: RomFileMetadata {
                leading_bytes: repr_c::Vec::from(b"TENTH LEADING".to_vec()),
                ..rom_file.metadata
            },
        };
        assert_eq!(rom_file.check_signature(), false);
    }
}
