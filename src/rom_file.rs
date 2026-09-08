use anyhow::{Context, Result, anyhow};
use std::ffi::OsString;
use std::fs::File;
use std::io::Read;
use std::path::Path;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RomFile {
    filename: OsString,
    file_stem: OsString,
    extension: OsString,
    data: Vec<u8>,
}

impl RomFile {
    pub fn open(path: &str) -> Result<Self> {
        let path = Path::new(path);

        let mut file = File::open(path)
            .map_err(|e| anyhow!("Failed to open ROM file {}: {}", path.display(), e))?;

        let mut data = Vec::new();
        file.read_to_end(&mut data)?;

        Ok(RomFile {
            filename: path
                .file_name()
                .with_context(|| format!("Failed to get filename from path {}", path.display()))?
                .to_owned(),
            extension: path
                .extension()
                .with_context(|| format!("Failed to get extension from path {}", path.display()))?
                .to_owned(),
            file_stem: path
                .file_stem()
                .with_context(|| format!("Failed to get file stem from path {}", path.display()))?
                .to_owned(),
            data,
        })
    }

    pub fn is_valid(&self) -> bool {
        self.data.len() > 0
    }

    pub fn size(&self) -> usize {
        self.data.len()
    }

    pub fn check_signature(&self, signatures: Vec<&[u8]>) -> Result<()> {
        if self.data.len() < 4 {
            return Err(anyhow!("ROM file is too small to contain a valid header"));
        }
        if !signatures
            .iter()
            .any(|&sig| &self.data[0..sig.len()] == sig)
        {
            return Err(anyhow!("Invalid ROM file signature"));
        }
        Ok(())
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_open() -> Result<()> {
        let rom_file = RomFile::open("./Super Mario Bros. 3 (USA) (Rev 1).nes")?;
        assert_eq!(
            rom_file.filename,
            OsString::from("Super Mario Bros. 3 (USA) (Rev 1).nes")
        );
        assert_eq!(
            rom_file.file_stem,
            OsString::from("Super Mario Bros. 3 (USA) (Rev 1)")
        );
        assert_eq!(rom_file.extension, OsString::from("nes"));
        assert_eq!(rom_file.is_valid(), true);
        assert_eq!(rom_file.size(), 393232);
        assert_eq!(
            rom_file
                .check_signature(vec![
                    b"NES\x1a",
                    b"FDS\x1a",
                    b"\x1a*NINTENDO-HVC*",
                    b"NESM\x1a",
                    b"NSFE",
                    b"UNIF",
                    b"STBX"
                ])
                .is_ok(),
            true
        );

        Ok(())
    }
}
