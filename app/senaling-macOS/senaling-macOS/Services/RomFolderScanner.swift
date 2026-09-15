//
//  RomScan.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 12/09/2026.
//
import Foundation
import OSLog
import SenalingCore
import SenalingMacros
import SwiftData
import SwiftUI

protocol IRomFolderScanner {

  var isScanning: Bool { get }

  func run(folderURL: URL)

  func cancel()
}

@Observable
@Logged
final class RomFolderScanner: IRomFolderScanner {

  nonisolated private let runner: Runner

  init(modelContainer: ModelContainer) {
    self.runner = Runner(modelContainer: modelContainer)
  }

  private(set) var isScanning = false

  func run(folderURL: URL) {
    Task {
      isScanning = true
      await runner.run(folderURL) { [weak self] in
        self?.isScanning = false
      }
    }
  }

  func cancel() {
    Task {
      await runner.cancel()
    }
  }

  nonisolated struct RomFileAsyncIterator: AsyncSequence {

    typealias Element = (Data, RomInspection)

    let folderURL: URL

    func makeAsyncIterator() -> AsyncIterator {
      AsyncIterator(folderURL)
    }

    @Logged
    nonisolated struct AsyncIterator: AsyncIteratorProtocol {
      typealias Element = (Data, RomInspection)

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

  @Logged
  @ModelActor
  nonisolated actor Runner: Sendable {

    private var workerTask: Task<Void, Never>?

    func run(_ folderURL: URL, onComplete: @escaping () -> Void) {
      guard workerTask == nil else {
        Self.logger.debug("Existing task is still running")
        return
      }

      workerTask = Task {
        defer {
          onComplete()
          workerTask = nil
        }

        do {
          let didStart = folderURL.startAccessingSecurityScopedResource()
          defer {
            if didStart {
              folderURL.stopAccessingSecurityScopedResource()
            }
          }

          Self.logger.debug("Running task: \(folderURL)")

          for try await (bookmark, romInspection) in RomFileAsyncIterator(
            folderURL: folderURL
          ) {
            let romFile = RomFile(
              bookmark: bookmark,
              romInspection: romInspection
            )
            do {
              modelContext.insert(romFile)
              try modelContext.save()
            } catch {
              Self.logger.error("Unable to save \(romFile). Reason: \(error)")
            }
          }
        } catch is CancellationError {
          Self.logger.debug("Job cancelled")
        } catch {
          Self.logger.warning("Unable to iterate. Reason: \(error)")
        }
      }
    }

    func cancel() {
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

  func run(folderURL: URL) {
    isScanning = true
  }

  func cancel() {
    isScanning = false
  }
}
