import Foundation
import Testing

@testable import SenalingCore

@Test func returnsTypeNameForMatchingSignature() {
  let leadingBytes = Data("NES\u{001A}ROM-DATA-HERE".utf8)

  #expect(SignatureCheck.getSignatureCheck(leadingBytes: leadingBytes) == "NES")
}

@Test func returnsNilForUnknownSignature() {
  let leadingBytes = Data("UNKNOWN-ROM-DATA".utf8)

  #expect(SignatureCheck.getSignatureCheck(leadingBytes: leadingBytes) == nil)
}

@Test func acceptsEmptyData() {
  #expect(SignatureCheck.getSignatureCheck(leadingBytes: Data()) == nil)
}
