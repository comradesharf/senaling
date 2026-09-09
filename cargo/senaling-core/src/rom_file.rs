use crate::nes::rom_file::NesRomFile;
pub use crate::shared::rom_file::{RomFile, RomFileMetadata};
use crate::test::rom_file::TestRomFile;
use std::sync::Arc;

const ROM_FILES: &[fn(&RomFileMetadata) -> Arc<dyn RomFile>] = &[
    |metadata| Arc::new(NesRomFile::new(metadata)),
    |metadata| Arc::new(TestRomFile::new(metadata)),
];

#[uniffi::export]
pub fn get_rom_file(metadata: &RomFileMetadata) -> Option<Arc<dyn RomFile>> {
    ROM_FILES.iter().find_map(|create_rom_file| {
        let rom_file = create_rom_file(metadata);
        if rom_file.check_signature() {
            Some(rom_file)
        } else {
            None
        }
    })
}
