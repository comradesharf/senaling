use crate::shared::rom_file::{RomFile, RomFileMetadata};

#[derive(Debug, Clone)]
pub struct NesRomFile {
    metadata: RomFileMetadata,
}

const NES_SIGNATURES: &[&[u8]] = &[
    b"NES\x1a",
    b"FDS\x1a",
    b"\x1a*NINTENDO-HVC*",
    b"NESM\x1a",
    b"NSFE",
    b"UNIF",
    b"STBX",
];

impl NesRomFile {
    pub fn new(metadata: &RomFileMetadata) -> Self {
        NesRomFile {
            metadata: metadata.to_owned(),
        }
    }
}

impl RomFile for NesRomFile {
    fn metadata(&self) -> &RomFileMetadata {
        &self.metadata
    }

    fn signatures(&self) -> &[&[u8]] {
        NES_SIGNATURES
    }
}
