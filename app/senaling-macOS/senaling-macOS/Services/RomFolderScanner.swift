//
//  RomScan.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 12/09/2026.
//
import Foundation
import SenalingCore

struct RomFolderScannerJob: Sendable {
  enum State: Sendable {
    case queued
    case scanning(fileCount: Int)
    case completed(fileCount: Int)
    case failed(message: String)
    case cancelled
  }

  let folderURL: URL
  var state: State = State.queued

  init(_ folderURL: URL) {
    self.folderURL = folderURL
  }
}

struct RomFolderScanner: AsyncSequence {
  typealias Element = RomInspection

  let folderURL: URL

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(folderURL)
  }

  struct AsyncIterator: AsyncIteratorProtocol {
    typealias Element = RomInspection

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

    mutating func next() async throws -> RomInspection? {
      try Task.checkCancellation()

      while true {
        guard let fileURL = enumerator?.nextObject() as? URL else {
          return nil
        }

        let didStart = fileURL.startAccessingSecurityScopedResource()
        defer {
          if didStart {
            fileURL.stopAccessingSecurityScopedResource()
          }
        }

        let values = try fileURL.resourceValues(forKeys: keys)

        guard values.isRegularFile == true else {
          continue
        }

        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        do {
          return try RomInspection.inspect(fileHandle: fileHandle)
        } catch {
          continue
        }
      }
    }
  }

  //  private func getFileURLs(_ folderURL: URL) throws -> [URL] {
  //    guard
  //      let enumerator = FileManager.default.enumerator(
  //        at: folderURL,
  //        includingPropertiesForKeys: Array(keys),
  //        options: [.skipsHiddenFiles, .skipsPackageDescendants]
  //      )
  //    else {
  //      throw CocoaError(.fileReadUnknown)
  //    }
  //
  //    var fileURLs: [URL] = []
  //    while let fileURL = enumerator.nextObject() as? URL {
  //      fileURLs.append(fileURL)
  //    }
  //
  //    return fileURLs
  //  }
  //
  //  func scan(folderURL: URL, onFileFound: @Sendable (URL, Int) async -> Void) async throws -> Int {
  //    let fileURLs = try getFileURLs(folderURL)
  //    var count = 0
  //
  //    for case let fileURL in fileURLs {
  //      try Task.checkCancellation()
  //
  //      let values = try fileURL.resourceValues(forKeys: keys)
  //
  //      guard values.isRegularFile == true else {
  //        continue
  //      }
  //
  //      count += 1
  //
  //      await onFileFound(fileURL, count)
  //    }
  //
  //    return count
  //  }
}

//protocol IRomFolderScannerRunner: Actor {
//
//  typealias StatusHandler = (RomFolderScannerJob.State) async -> Void
//
//  func run(_ job: RomFolderScannerJob, statusHandler: @escaping StatusHandler) async
//
//  func cancel()
//}
//
//actor RomFolderScannerRunner: IRomFolderScannerRunner, Sendable {
//
//  private var workerTask: Task<Void, Never>?
//
//  private var scanner: IRomFolderScanner
//
//  init(scanner: IRomFolderScanner) {
//    self.scanner = scanner
//  }
//
//  func run(
//    _ job: RomFolderScannerJob,
//    statusHandler: @escaping StatusHandler
//  ) async {
//    guard workerTask == nil else {
//      return
//    }
//
//    workerTask = Task {
//      await statusHandler(.scanning(fileCount: 0))
//      guard job.folderURL.startAccessingSecurityScopedResource() else {
//        await statusHandler(.failed(message: "No permission to access folder"))
//        return
//      }
//      defer {
//        job.folderURL.stopAccessingSecurityScopedResource()
//      }
//
//      do {
//        let count = try await scanner.scan(folderURL: job.folderURL) { fileURL, count in
//          await statusHandler(.scanning(fileCount: count))
//          print("Found", fileURL.path(percentEncoded: false))
//        }
//        await statusHandler(.completed(fileCount: count))
//      } catch is CancellationError {
//        await statusHandler(.cancelled)
//      } catch {
//        await statusHandler(.failed(message: error.localizedDescription))
//      }
//    }
//  }
//
//  func cancel() {
//    workerTask?.cancel()
//    workerTask = nil
//  }
//}
//
//protocol IRomFolderScannerStore {
//
//  func start(_ folderURL: URL)
//
//  func cancel()
//}
//
//@Observable
//final class RomFolderScannerStore: IRomFolderScannerStore {
//
//  private let runner: IRomFolderScannerRunner
//
//  init(runner: IRomFolderScannerRunner) {
//    self.runner = runner
//  }
//
//  func start(_ folderURL: URL) {
//    Task {
//      await runner.run(RomFolderScannerJob(folderURL)) { _ in }
//    }
//  }
//
//  func cancel() {
//    Task {
//      await runner.cancel()
//    }
//  }
//}
//
//@Observable
//final class MockedRomFolderScannerStore: IRomFolderScannerStore {
//
//  func start(_ folderURL: URL) {}
//
//  func cancel() {}
//}
