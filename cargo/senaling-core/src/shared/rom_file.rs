#[derive(uniffi::Record, Debug, Clone, PartialEq, Eq)]
#[uniffi::export(Debug, Debug, Eq)]
pub struct RomFileMetadata {
    pub path: String,
    pub leading_bytes: Vec<u8>,
}

#[uniffi::export]
pub trait RomFile: Send + Sync {
    fn check_signature(&self) -> bool;
    fn metadata(&self) -> RomFileMetadata;
}

pub trait BaseRomFile: RomFile {
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

#[cfg(test)]
mod tests {
    use super::*;

    struct TestRomFile {
        metadata: RomFileMetadata,
    }

    impl RomFile for TestRomFile {
        fn check_signature(&self) -> bool {
            <Self as BaseRomFile>::check_signature(self)
        }
        fn metadata(&self) -> RomFileMetadata {
            self.metadata.to_owned()
        }
    }

    impl BaseRomFile for TestRomFile {
        fn signatures(&self) -> &[&[u8]] {
            &[b"TEST"]
        }
    }

    #[test]
    fn test_check_signature() {
        let rom_file = TestRomFile {
            metadata: RomFileMetadata {
                path: String::from("test_path"),
                leading_bytes: b"TEST".to_vec(),
            },
        };
        assert_eq!(
            <TestRomFile as BaseRomFile>::check_signature(&rom_file),
            true
        );

        let rom_file = TestRomFile {
            metadata: RomFileMetadata {
                leading_bytes: b"TE".to_vec(),
                ..rom_file.metadata
            },
        };
        assert_eq!(
            <TestRomFile as BaseRomFile>::check_signature(&rom_file),
            false
        );
    }
}
