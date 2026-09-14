use std::io::Read;

use anyhow::{Context, Result, bail};
use crc32fast::Hasher as Crc32Hasher;
use md5::Md5;
use sha1::Sha1;
use sha2::{Digest, Sha256};

use crate::shared::rom_inspection::{
    FileInfo, FormatInfo, Hashes, Identifiers, MediaType, RomInspection, RomInspector,
};

const NES_PLATFORM: &str = "NES";
const READ_BUFFER_SIZE: usize = 64 * 1024;
const HEADER_INSPECTION_SIZE: usize = 16;

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct NesRomInspector;

impl NesRomInspector {
    pub fn new() -> Self {
        Self
    }
}

impl RomInspector for NesRomInspector {
    fn inspect(&self, reader: &mut dyn Read) -> Result<RomInspection> {
        let (leading_bytes, size, hashes) = read_and_hash(reader)?;
        let format = inspect_format(&leading_bytes)?;

        Ok(RomInspection {
            file: FileInfo { size },
            hashes,
            format,
            identifiers: Identifiers {
                title: None,
                serial: None,
                product_code: None,
                volume_label: None,
                disc_id: None,
                region: None,
                revision: None,
            },
            platform: NES_PLATFORM.to_owned(),
        })
    }
}

fn inspect_format(bytes: &[u8]) -> Result<FormatInfo> {
    let (container, header, media_type) = if bytes.starts_with(b"NES\x1a") {
        if bytes.len() < 16 {
            bail!("invalid iNES ROM: the 16-byte header is incomplete");
        }

        let header = if bytes[7] & 0x0c == 0x08 {
            "NES 2.0"
        } else {
            "iNES"
        };
        ("iNES", header, MediaType::Cartridge)
    } else if bytes.starts_with(b"FDS\x1a") {
        ("FDS", "FDS", MediaType::DiskImage)
    } else if bytes.starts_with(b"\x1a*NINTENDO-HVC*") {
        ("FDS", "fwNES", MediaType::DiskImage)
    } else if bytes.starts_with(b"NESM\x1a") {
        ("NSF", "NESM", MediaType::RomImage)
    } else if bytes.starts_with(b"NSFE") {
        ("NSFe", "NSFE", MediaType::RomImage)
    } else if bytes.starts_with(b"UNIF") {
        ("UNIF", "UNIF", MediaType::Cartridge)
    } else if bytes.starts_with(b"STBX") {
        ("StudyBox", "STBX", MediaType::RomImage)
    } else {
        bail!("unsupported NES ROM format");
    };

    Ok(FormatInfo {
        container: Some(container.to_owned()),
        header: Some(header.to_owned()),
        media_type,
    })
}

fn read_and_hash(reader: &mut dyn Read) -> Result<(Vec<u8>, u64, Hashes)> {
    let mut buffer = [0_u8; READ_BUFFER_SIZE];
    let mut leading_bytes = Vec::with_capacity(HEADER_INSPECTION_SIZE);
    let mut size = 0_u64;
    let mut crc32 = Crc32Hasher::new();
    let mut md5 = Md5::new();
    let mut sha1 = Sha1::new();
    let mut sha256 = Sha256::new();

    loop {
        let bytes_read = reader
            .read(&mut buffer)
            .context("failed while reading NES ROM file")?;
        if bytes_read == 0 {
            break;
        }

        let chunk = &buffer[..bytes_read];
        if leading_bytes.len() < HEADER_INSPECTION_SIZE {
            let bytes_needed = HEADER_INSPECTION_SIZE - leading_bytes.len();
            leading_bytes.extend_from_slice(&chunk[..chunk.len().min(bytes_needed)]);
        }

        size += bytes_read as u64;
        crc32.update(chunk);
        md5.update(chunk);
        sha1.update(chunk);
        sha256.update(chunk);
    }

    Ok((
        leading_bytes,
        size,
        Hashes {
            crc32: format!("{:08x}", crc32.finalize()),
            md5: format!("{:x}", md5.finalize()),
            sha1: format!("{:x}", sha1.finalize()),
            sha256: format!("{:x}", sha256.finalize()),
        },
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn identifies_ines_and_nes_2_headers() -> Result<()> {
        let mut ines = [0_u8; 16];
        ines[..4].copy_from_slice(b"NES\x1a");

        let format = inspect_format(&ines)?;
        assert_eq!(format.container.as_deref(), Some("iNES"));
        assert_eq!(format.header.as_deref(), Some("iNES"));
        assert_eq!(format.media_type, MediaType::Cartridge);

        ines[7] = 0x08;
        let format = inspect_format(&ines)?;
        assert_eq!(format.header.as_deref(), Some("NES 2.0"));

        Ok(())
    }

    #[test]
    fn identifies_other_supported_nes_formats() -> Result<()> {
        let cases: &[(&[u8], &str, MediaType)] = &[
            (b"FDS\x1a", "FDS", MediaType::DiskImage),
            (b"\x1a*NINTENDO-HVC*", "FDS", MediaType::DiskImage),
            (b"NESM\x1a", "NSF", MediaType::RomImage),
            (b"NSFE", "NSFe", MediaType::RomImage),
            (b"UNIF", "UNIF", MediaType::Cartridge),
            (b"STBX", "StudyBox", MediaType::RomImage),
        ];

        for (bytes, expected_container, expected_media_type) in cases {
            let format = inspect_format(bytes)?;
            assert_eq!(format.container.as_deref(), Some(*expected_container));
            assert_eq!(format.media_type, *expected_media_type);
        }
        Ok(())
    }

    #[test]
    fn rejects_incomplete_or_unsupported_files() {
        assert!(inspect_format(b"NES\x1a").is_err());
        assert!(inspect_format(b"not a NES ROM").is_err());
    }

    #[test]
    fn calculates_all_hashes_without_buffering_the_entire_file() -> Result<()> {
        let (_, size, hashes) = read_and_hash(&mut &b"abc"[..])?;

        assert_eq!(size, 3);
        assert_eq!(hashes.crc32, "352441c2");
        assert_eq!(hashes.md5, "900150983cd24fb0d6963f7d28e17f72");
        assert_eq!(hashes.sha1, "a9993e364706816aba3e25717850c26c9cd0d89d");
        assert_eq!(
            hashes.sha256,
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );

        Ok(())
    }

    #[test]
    fn inspects_rom_from_reader_end_to_end() -> Result<()> {
        let mut rom = [0_u8; 16];
        rom[..4].copy_from_slice(b"NES\x1a");

        let inspection = NesRomInspector::new().inspect(&mut &rom[..])?;

        assert_eq!(inspection.file.size, 16);
        assert_eq!(inspection.platform, NES_PLATFORM);
        assert_eq!(inspection.format.header.as_deref(), Some("iNES"));

        Ok(())
    }
}
