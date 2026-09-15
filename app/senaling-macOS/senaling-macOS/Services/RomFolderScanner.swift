//
//  RomScan.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 12/09/2026.
//
import Foundation
import OSLog
import SenalingCore
import SwiftData
import SwiftUI

protocol IRomFolderScanner {

  var isScanning: Bool { get }

  func run(folderURL: URL, handler: @escaping (Data, RomInspection) -> Void)

  func cancel()
}

@Observable
final class RomFolderScanner: IRomFolderScanner {

  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "comradesharf",
    category: String(describing: RomFolderScanner.self)
  )

  private let runner = Runner()

  private(set) var isScanning = false

  func run(folderURL: URL, handler: @escaping (Data, RomInspection) -> Void) {
    Task {
      isScanning = true
      await runner.run(folderURL, handler: handler)
      isScanning = false
    }
  }

  func cancel() {
    Task {
      await runner.cancel()
      isScanning = false
    }
  }

  struct RomFileAsyncIterator: AsyncSequence {

    typealias Element = (Data, RomInspection)

    let folderURL: URL

    func makeAsyncIterator() -> AsyncIterator {
      AsyncIterator(folderURL)
    }

    struct AsyncIterator: AsyncIteratorProtocol {
      typealias Element = (Data, RomInspection)

      private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "comradesharf",
        category: String(describing: AsyncIterator.self)
      )

      private let keys: Set<URLResourceKey> = [
        .isRegularFileKey,
        .isDirectoryKey,
        .isHiddenKey,
      ]

      private var enumerator: FileManager.DirectoryEnumerator?

      init(_ folderURL: URL) {
        self.enumerator = FileManager.default.enumerator(
          at: folderURL,
          includingPropertiesForKeys: Array(keys),
          options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
      }

      mutating func next() async throws -> (Data, RomInspection)? {
        while true {
          try Task.checkCancellation()

          guard let fileURL = enumerator?.nextObject() as? URL else {
            Self.logger.debug("No more file. Returning nil")
            return nil
          }

          let values = try fileURL.resourceValues(forKeys: keys)

          guard values.isRegularFile == true else {
            continue
          }

          do {
            Self.logger.info("Checking for file: \(fileURL)")

            let romInspection = try {
              let fileHandle = try FileHandle(forReadingFrom: fileURL)
              defer {
                Self.logger.info("Closing file handle: \(fileURL)")
                try? fileHandle.close()
              }

              return try RomInspection.inspect(fileHandle: fileHandle)
            }()

            Self.logger.debug("Creating bookmark: \(fileURL)")

            let bookmark = try fileURL.bookmarkData(
              options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
              includingResourceValuesForKeys: nil,
              relativeTo: nil
            )

            return (bookmark, romInspection)
          } catch SenalingCore.RomInspectionError.internalFailure(let diagnostic) {
            Self.logger.warning("Internal failure. Reason: \(diagnostic ?? "N/A")")
            continue
          } catch SenalingCore.RomInspectionError.io(let diagnostic) {
            Self.logger.warning("IO failure. Reason: \(diagnostic ?? "N/A")")
            continue
          } catch SenalingCore.RomInspectionError.invalidRom {
            continue
          } catch {
            Self.logger.warning("Unable to inspect file. Reason: \(error)")
            continue
          }
        }
      }
    }
  }

  private actor Runner: Sendable {

    private static let logger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "comradesharf",
      category: String(describing: RomFolderScanner.self)
    )

    private var workerTask: Task<Void, Never>?

    func run(
      _ folderURL: URL,
      handler: @escaping (Data, RomInspection) -> Void
    ) {
      guard workerTask == nil else {
        Self.logger.debug("Existing task is still running")
        return
      }

      workerTask = Task {
        do {
          let didStart = folderURL.startAccessingSecurityScopedResource()
          defer {
            if didStart {
              folderURL.stopAccessingSecurityScopedResource()
            }
          }

          Self.logger.debug("Running task: \(folderURL)")

          for try await (bookmark, romInspection) in RomFileAsyncIterator(folderURL: folderURL) {
            handler(bookmark, romInspection)
          }
        } catch {
          cancel()
        }
      }
    }

    func cancel() {
      Self.logger.debug("Cancelling running task")
      workerTask?.cancel()
      workerTask = nil
      Self.logger.debug("Running task cancelled")
    }

  }

}

@Observable
final class MockRomFolderScanner: IRomFolderScanner {

  private(set) var isScanning: Bool

  init(isScanning: Bool) {
    self.isScanning = isScanning
  }

  func run(folderURL: URL, handler: @escaping (Data, SenalingCore.RomInspection) -> Void) {
    isScanning = true
  }

  func cancel() {
    isScanning = false
  }
}

extension EnvironmentValues {
  @Entry var romFolderScanner: IRomFolderScanner = RomFolderScanner()
}
