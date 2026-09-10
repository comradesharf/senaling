use crate::nes::rom_file::NesRomFile;
use crate::shared::rom_file::RomFileHandle;
pub use crate::shared::rom_file::{RomFile, RomFileMetadata};
use ::safer_ffi::prelude::*;
use std::rc::Rc;

const ROM_FILES: &[fn(&RomFileMetadata) -> RomFileHandle] = &[|metadata| RomFileHandle {
    rom_file: Rc::new(NesRomFile::new(metadata)),
}];

#[ffi_export]
pub fn get_rom_file(metadata: &RomFileMetadata) -> *mut RomFileHandle {
    ROM_FILES
        .iter()
        .find_map(|create_rom_file| {
            let rom_file = create_rom_file(metadata);

            if !rom_file.rom_file.check_signature() {
                return None;
            }

            Some(Box::into_raw(Box::new(rom_file)))
        })
        .unwrap_or_else(std::ptr::null_mut)
}
