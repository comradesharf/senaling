use crate::shared::rom_file::{BaseRomFile, RomFile, RomFileMetadata};

#[derive(uniffi::Record, Debug, Clone, PartialEq, Eq)]
#[uniffi::export(Debug, Debug, Eq)]
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
    fn check_signature(&self) -> bool {
        <Self as BaseRomFile>::check_signature(self)
    }

    fn metadata(&self) -> RomFileMetadata {
        self.metadata.to_owned()
    }
}

impl BaseRomFile for NesRomFile {
    fn signatures(&self) -> &[&[u8]] {
        NES_SIGNATURES
    }
}
