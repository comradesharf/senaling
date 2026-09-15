use std::{
    fs::File,
    io::{self, Read},
    os::{fd::FromRawFd, unix::fs::FileExt},
    panic::{AssertUnwindSafe, catch_unwind},
};

use anyhow::Result;
use safer_ffi::prelude::*;
use senaling_core::{
    nes::rom_inspector::NesRomInspector,
    shared::rom_inspection::{
        FileInfo, FormatInfo, Hashes, Identifiers, MediaType, RomInspection, RomInspector,
    },
};

#[derive_ReprC]
#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RomInspectionErrorCode {
    Ok = 0,
    InvalidArgument = 1,
    InvalidRom = 2,
    Io = 3,
    Internal = 4,
}

#[derive_ReprC]
#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FfiMediaType {
    Cartridge = 0,
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

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct FfiFileInfo {
    pub size: u64,
}

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct FfiHashes {
    pub crc32: repr_c::String,
    pub md5: repr_c::String,
    pub sha1: repr_c::String,
    pub sha256: repr_c::String,
}

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct FfiFormatInfo {
    pub container: repr_c::TaggedOption<repr_c::String>,
    pub header: repr_c::TaggedOption<repr_c::String>,
    pub media_type: FfiMediaType,
}

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct FfiIdentifiers {
    pub title: repr_c::TaggedOption<repr_c::String>,
    pub serial: repr_c::TaggedOption<repr_c::String>,
    pub product_code: repr_c::TaggedOption<repr_c::String>,
    pub volume_label: repr_c::TaggedOption<repr_c::String>,
    pub disc_id: repr_c::TaggedOption<repr_c::String>,
    pub region: repr_c::TaggedOption<repr_c::String>,
    pub revision: repr_c::TaggedOption<repr_c::String>,
}

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct FfiRomInspection {
    pub file: FfiFileInfo,
    pub hashes: FfiHashes,
    pub format: FfiFormatInfo,
    pub identifiers: FfiIdentifiers,
    pub platform: repr_c::String,
}

#[derive_ReprC]
#[repr(C)]
#[derive(Debug, Clone)]
pub struct FfiRomInspectionResult {
    pub error_code: RomInspectionErrorCode,
    pub inspection: repr_c::TaggedOption<FfiRomInspection>,
    pub diagnostic: repr_c::TaggedOption<repr_c::String>,
}

#[ffi_export]
/// Inspects the ROM exposed by a borrowed Unix file descriptor.
///
/// Rust duplicates the descriptor and does not close the caller's descriptor or
/// change its file offset. The caller must keep the descriptor open until this
/// function returns.
///
/// The returned value owns all of its strings. Pass it to
/// [`rom_inspection_result_free`] exactly once, including error results.
pub fn inspect_rom(file_descriptor: i32) -> FfiRomInspectionResult {
    match catch_unwind(AssertUnwindSafe(|| {
        let file = duplicate_file_descriptor(file_descriptor)?;
        let mut reader = PositionedFileReader::new(file);
        NesRomInspector::new()
            .inspect(&mut reader)
            .map_err(InspectRomError::Inspection)
    })) {
        Ok(Ok(inspection)) => FfiRomInspectionResult {
            error_code: RomInspectionErrorCode::Ok,
            inspection: repr_c::TaggedOption::Some(inspection.into()),
            diagnostic: repr_c::TaggedOption::None,
        },
        Ok(Err(error)) => error.into_result(),
        Err(_) => FfiRomInspectionResult {
            error_code: RomInspectionErrorCode::Internal,
            inspection: repr_c::TaggedOption::None,
            diagnostic: repr_c::TaggedOption::Some("unexpected panic while inspecting ROM".into()),
        },
    }
}

#[derive(Debug)]
enum InspectRomError {
    InvalidFileDescriptor(io::Error),
    Inspection(anyhow::Error),
}

impl InspectRomError {
    fn into_result(self) -> FfiRomInspectionResult {
        let (error_code, diagnostic) = match self {
            Self::InvalidFileDescriptor(error) => {
                (RomInspectionErrorCode::InvalidArgument, error.to_string())
            }
            Self::Inspection(error) if error.downcast_ref::<io::Error>().is_some() => {
                (RomInspectionErrorCode::Io, error.to_string())
            }
            Self::Inspection(error) => (RomInspectionErrorCode::InvalidRom, error.to_string()),
        };

        FfiRomInspectionResult {
            error_code,
            inspection: repr_c::TaggedOption::None,
            diagnostic: repr_c::TaggedOption::Some(diagnostic.into()),
        }
    }
}

fn duplicate_file_descriptor(file_descriptor: i32) -> Result<File, InspectRomError> {
    if file_descriptor < 0 {
        return Err(InspectRomError::InvalidFileDescriptor(io::Error::new(
            io::ErrorKind::InvalidInput,
            "file descriptor must be non-negative",
        )));
    }

    // SAFETY: `dup` accepts any integer and either returns a new owned file
    // descriptor or reports an OS error. A successful result is uniquely owned.
    let duplicated = unsafe { libc::dup(file_descriptor) };
    if duplicated == -1 {
        return Err(InspectRomError::InvalidFileDescriptor(
            io::Error::last_os_error(),
        ));
    }

    // SAFETY: `duplicated` was returned successfully by `dup`, and ownership is
    // transferred exactly once to `File`.
    Ok(unsafe { File::from_raw_fd(duplicated) })
}

struct PositionedFileReader {
    file: File,
    offset: u64,
}

impl PositionedFileReader {
    fn new(file: File) -> Self {
        Self { file, offset: 0 }
    }
}

impl Read for PositionedFileReader {
    fn read(&mut self, buffer: &mut [u8]) -> io::Result<usize> {
        let bytes_read = self.file.read_at(buffer, self.offset)?;
        self.offset = self
            .offset
            .checked_add(bytes_read as u64)
            .ok_or_else(|| io::Error::other("ROM file offset overflow"))?;
        Ok(bytes_read)
    }
}

#[ffi_export]
/// Releases a result returned by [`inspect_rom`].
pub fn rom_inspection_result_free(result: FfiRomInspectionResult) {
    drop(result);
}

impl From<RomInspection> for FfiRomInspection {
    fn from(inspection: RomInspection) -> Self {
        let RomInspection {
            file,
            hashes,
            format,
            identifiers,
            platform,
        } = inspection;

        Self {
            file: file.into(),
            hashes: hashes.into(),
            format: format.into(),
            identifiers: identifiers.into(),
            platform: platform.into(),
        }
    }
}

impl From<FileInfo> for FfiFileInfo {
    fn from(file: FileInfo) -> Self {
        let FileInfo { size } = file;

        Self { size }
    }
}

impl From<Hashes> for FfiHashes {
    fn from(hashes: Hashes) -> Self {
        let Hashes {
            crc32,
            md5,
            sha1,
            sha256,
        } = hashes;

        Self {
            crc32: crc32.into(),
            md5: md5.into(),
            sha1: sha1.into(),
            sha256: sha256.into(),
        }
    }
}

impl From<FormatInfo> for FfiFormatInfo {
    fn from(format: FormatInfo) -> Self {
        let FormatInfo {
            container,
            header,
            media_type,
        } = format;

        Self {
            container: to_ffi_string(container),
            header: to_ffi_string(header),
            media_type: media_type.into(),
        }
    }
}

impl From<Identifiers> for FfiIdentifiers {
    fn from(identifiers: Identifiers) -> Self {
        let Identifiers {
            title,
            serial,
            product_code,
            volume_label,
            disc_id,
            region,
            revision,
        } = identifiers;

        Self {
            title: to_ffi_string(title),
            serial: to_ffi_string(serial),
            product_code: to_ffi_string(product_code),
            volume_label: to_ffi_string(volume_label),
            disc_id: to_ffi_string(disc_id),
            region: to_ffi_string(region),
            revision: to_ffi_string(revision),
        }
    }
}

impl From<MediaType> for FfiMediaType {
    fn from(media_type: MediaType) -> Self {
        match media_type {
            MediaType::Cartridge => Self::Cartridge,
            MediaType::CdRom => Self::CdRom,
            MediaType::DvdRom => Self::DvdRom,
            MediaType::BluRay => Self::BluRay,
            MediaType::Umd => Self::Umd,
            MediaType::FloppyDisk => Self::FloppyDisk,
            MediaType::HardDisk => Self::HardDisk,
            MediaType::MagneticTape => Self::MagneticTape,
            MediaType::MemoryCard => Self::MemoryCard,
            MediaType::DiskImage => Self::DiskImage,
            MediaType::TapeImage => Self::TapeImage,
            MediaType::RomImage => Self::RomImage,
            MediaType::Archive => Self::Archive,
            MediaType::Unknown => Self::Unknown,
        }
    }
}

fn to_ffi_string(value: Option<String>) -> repr_c::TaggedOption<repr_c::String> {
    value.map(Into::into).into()
}

#[cfg(test)]
mod tests {
    use std::{
        io::{Seek, SeekFrom},
        os::fd::AsRawFd,
    };

    use super::*;

    #[test]
    fn returns_an_owned_inspection_without_changing_the_callers_offset() -> Result<()> {
        let mut rom = [0_u8; 16];
        rom[..4].copy_from_slice(b"NES\x1a");
        let path = temporary_rom_path("valid");
        std::fs::write(&path, rom)?;
        let mut file = File::open(&path)?;
        file.seek(SeekFrom::Start(7))?;

        let result = inspect_rom(file.as_raw_fd());

        assert_eq!(result.error_code, RomInspectionErrorCode::Ok);
        let inspection = result.inspection.as_ref().expect("inspection");
        assert_eq!(inspection.file.size, 16);
        assert_eq!(&*inspection.platform, "NES");
        assert_eq!(inspection.format.media_type, FfiMediaType::Cartridge);
        assert!(matches!(
            inspection.format.header,
            repr_c::TaggedOption::Some(ref header) if &**header == "iNES"
        ));
        assert_eq!(file.stream_position()?, 7);

        rom_inspection_result_free(result);
        drop(file);
        std::fs::remove_file(path)?;
        Ok(())
    }

    #[test]
    fn maps_an_unsupported_rom_to_a_stable_error_code() -> Result<()> {
        let path = temporary_rom_path("unsupported");
        std::fs::write(&path, b"not a rom")?;
        let file = File::open(&path)?;
        let result = inspect_rom(file.as_raw_fd());

        assert_eq!(result.error_code, RomInspectionErrorCode::InvalidRom);
        assert!(matches!(result.inspection, repr_c::TaggedOption::None));
        assert!(matches!(
            result.diagnostic,
            repr_c::TaggedOption::Some(ref message) if &**message == "unsupported NES ROM format"
        ));

        rom_inspection_result_free(result);
        drop(file);
        std::fs::remove_file(path)?;
        Ok(())
    }

    #[test]
    fn rejects_an_invalid_file_descriptor() {
        let result = inspect_rom(-1);

        assert_eq!(result.error_code, RomInspectionErrorCode::InvalidArgument);
        assert!(matches!(result.inspection, repr_c::TaggedOption::None));

        rom_inspection_result_free(result);
    }

    fn temporary_rom_path(name: &str) -> std::path::PathBuf {
        std::env::temp_dir().join(format!(
            "senaling-ffi-rom-inspection-{name}-{}",
            std::process::id()
        ))
    }
}
