use crate::shared::signature_check::SignatureCheck;

const NES_SIGNATURES: &[&[u8]] = &[
    b"NES\x1a",
    b"FDS\x1a",
    b"\x1a*NINTENDO-HVC*",
    b"NESM\x1a",
    b"NSFE",
    b"UNIF",
    b"STBX",
];

const NES_MAX_SIGNATURE_LENGTH: usize = {
    let mut max = 0;
    let mut index = 0;

    while index < NES_SIGNATURES.len() {
        let length = NES_SIGNATURES[index].len();
        if length > max {
            max = length;
        }
        index += 1;
    }

    max
};

const NES_TYPE_NAME: &str = "NES";

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct NesSignatureCheck {
    leading_bytes: Vec<u8>,
}

impl NesSignatureCheck {
    pub fn new(leading_bytes: Vec<u8>) -> Self {
        NesSignatureCheck { leading_bytes }
    }
}

impl SignatureCheck for NesSignatureCheck {
    fn leading_bytes(&self) -> &Vec<u8> {
        &self.leading_bytes
    }

    fn signatures(&self) -> &[&[u8]] {
        NES_SIGNATURES
    }

    fn max_signature_length(&self) -> usize {
        NES_MAX_SIGNATURE_LENGTH
    }

    fn type_name(&self) -> &'static str {
        NES_TYPE_NAME
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_check_signature() {
        let rom_file = NesSignatureCheck::new(b"NES\x1aISAGOODGAMETHATICANPLAY".to_vec());
        assert_eq!(rom_file.check_signature(), true);
        assert_eq!(rom_file.type_name(), NES_TYPE_NAME);
    }
}
