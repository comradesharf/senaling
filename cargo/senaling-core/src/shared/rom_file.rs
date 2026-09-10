#[derive(Debug, Clone, PartialEq, Eq)]
#[repr(C)]
pub struct RomFileMetadata {
    pub path: String,
    pub leading_bytes: Vec<u8>,
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

#[repr(C)]
pub struct RomFileHandle {
    pub rom_file: Box<dyn RomFile>,
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
                path: String::from("test_path"),
                leading_bytes: b"TEST LEADING".to_vec(),
            },
        };
        assert_eq!(rom_file.check_signature(), true);

        let rom_file = TestRomFile {
            metadata: RomFileMetadata {
                leading_bytes: b"TENTH LEADING".to_vec(),
                ..rom_file.metadata
            },
        };
        assert_eq!(rom_file.check_signature(), false);
    }
}
