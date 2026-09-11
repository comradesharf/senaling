//
//  SignatureCheck.swift
//  SenalingCore
//
//  Created by Hishammuddin Sani on 11/09/2026.
//

import Foundation
import senaling_ffi

public enum SignatureCheck {
  public static func getSignatureCheck(leadingBytes: Data) -> String? {
    leadingBytes.withUnsafeBytes { rawBuffer in
      if let baseAddress = rawBuffer.baseAddress {
        return getSignatureCheck(
          for: slice_ref_uint8_t(
            ptr: baseAddress.assumingMemoryBound(to: UInt8.self),
            len: rawBuffer.count
          )
        )
      }

      var emptyBufferSentinel: UInt8 = 0
      return withUnsafePointer(to: &emptyBufferSentinel) { pointer in
        getSignatureCheck(for: slice_ref_uint8_t(ptr: pointer, len: 0))
      }
    }
  }

  private static func getSignatureCheck(for leadingBytes: slice_ref_uint8_t) -> String? {
    let result = get_signature_check(leadingBytes)
    defer { signature_check_result_free(result) }

    guard result._0 else {
      return nil
    }

    return String(
      decoding: UnsafeBufferPointer(start: result._1.ptr, count: result._1.len),
      as: UTF8.self
    )
  }
}
