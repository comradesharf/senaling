use crate::shared::rom_file::{RomFile, RomFileMetadata};

#[derive(Debug, Clone, PartialEq, Eq)]
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
    fn metadata(&self) -> &RomFileMetadata {
        &self.metadata
    }
    fn signatures(&self) -> &[&[u8]] {
        TEST_SIGNATURES
    }
}
