use crate::shared::rom_file::{BaseRomFile, RomFile, RomFileMetadata};

#[derive(uniffi::Record, Debug, Clone, PartialEq, Eq)]
#[uniffi::export(Debug, Debug, Eq)]
pub struct TestRomFile {
    metadata: RomFileMetadata,
}

const TEST_SIGNATURES: &[&[u8]] = &[b"TEST"];

impl TestRomFile {
    pub fn new(metadata: &RomFileMetadata) -> Self {
        TestRomFile {
            metadata: metadata.clone(),
        }
    }
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
        TEST_SIGNATURES
    }
}
