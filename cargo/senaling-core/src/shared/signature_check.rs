pub trait SignatureCheck {
    fn leading_bytes(&self) -> &Vec<u8>;

    fn signatures(&self) -> &[&[u8]];

    fn max_signature_length(&self) -> usize;

    fn type_name(&self) -> &'static str;

    fn check_signature(&self) -> bool {
        self.leading_bytes().len() >= self.max_signature_length()
            && self
                .signatures()
                .iter()
                .any(|&sig| &self.leading_bytes()[0..sig.len()] == sig)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Debug, Clone, Eq, PartialEq)]
    struct TestSignatureCheck {
        leading_bytes: Vec<u8>,
        signatures: Vec<&'static [u8]>,
        max_signature_length: usize,
        type_name: &'static str,
    }

    impl TestSignatureCheck {
        fn new(
            leading_bytes: Vec<u8>,
            signatures: Vec<&'static [u8]>,
            type_name: &'static str,
        ) -> Self {
            TestSignatureCheck {
                leading_bytes,
                signatures: signatures.to_owned(),
                max_signature_length: signatures.iter().map(|sig| sig.len()).max().unwrap_or(0),
                type_name,
            }
        }
    }

    impl SignatureCheck for TestSignatureCheck {
        fn leading_bytes(&self) -> &Vec<u8> {
            &self.leading_bytes
        }
        fn signatures(&self) -> &[&[u8]] {
            &self.signatures
        }
        fn max_signature_length(&self) -> usize {
            self.max_signature_length
        }
        fn type_name(&self) -> &'static str {
            self.type_name
        }
    }

    #[test]
    fn test_check_signature() {
        let rom_file = TestSignatureCheck::new(
            b"TENTH LEADING".to_vec(),
            vec![b"TENTH", b"LEADING"],
            "TestSignatureCheck",
        );
        assert_eq!(rom_file.check_signature(), true);
        assert_eq!(rom_file.type_name(), "TestSignatureCheck");
    }
}
