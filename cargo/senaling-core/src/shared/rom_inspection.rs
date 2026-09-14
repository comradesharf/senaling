use std::io::Read;

use anyhow::Result;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RomInspection {
    pub file: FileInfo,
    pub hashes: Hashes,
    pub format: FormatInfo,
    pub identifiers: Identifiers,
    pub platform: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MediaType {
    Cartridge,
    CdRom,
    DvdRom,
    BluRay,
    Umd,
    FloppyDisk,
    HardDisk,
    MagneticTape,
    MemoryCard,
    DiskImage,
    TapeImage,
    RomImage,
    Archive,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileInfo {
    pub size: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Hashes {
    pub crc32: String,
    pub md5: String,
    pub sha1: String,
    pub sha256: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FormatInfo {
    pub container: Option<String>,
    pub header: Option<String>,
    pub media_type: MediaType,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Identifiers {
    pub title: Option<String>,
    pub serial: Option<String>,
    pub product_code: Option<String>,
    pub volume_label: Option<String>,
    pub disc_id: Option<String>,
    pub region: Option<String>,
    pub revision: Option<String>,
}

pub trait RomInspector {
    fn inspect(&self, reader: &mut dyn Read) -> Result<RomInspection>;
}
