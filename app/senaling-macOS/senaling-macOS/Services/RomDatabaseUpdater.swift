//
//  RomDetailsService.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 16/09/2026.
//

import Foundation
import OSLog
import SenalingMacros
import SwiftData

@Logged
@Observable
final class RomDatabaseUpdater {

  nonisolated private let runner: Runner

  private(set) var isUpdating = false

  init(modelContainer: ModelContainer) {
    self.runner = Runner(modelContainer: modelContainer)
  }

  func run() {
    Task {
      isUpdating = true
      await runner.run { [weak self] in
        self?.isUpdating = false
      }
    }
  }

  func cancel() {
    Task {
      await runner.cancel()
    }
  }

  @Logged
  nonisolated struct Service: Sendable {

    private static let noIntroDatabaseURL = URL(
      string:
        "https://raw.githubusercontent.com/libretro/libretro-database/refs/heads/master/metadat/no-intro/Nintendo%20-%20Nintendo%20Entertainment%20System.dat"
    )!

    func fetch() async throws -> ClrMameProDatabase {
      try Task.checkCancellation()

      let (data, response) = try await URLSession.shared.data(from: Self.noIntroDatabaseURL)
      guard
        let response = response as? HTTPURLResponse,
        (200..<300).contains(response.statusCode)
      else {
        throw URLError(.badServerResponse)
      }

      Self.logger.debug("Fetched latest database")
      return try ClrMameProParser().parse(data)
    }
  }

  @ModelActor
  @Logged
  nonisolated actor Runner: Sendable {

    private let service = Service()

    private var workerTask: Task<Void, Never>?

    func run(onComplete: @escaping () -> Void) {
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
          Self.logger.debug("Updating database")
          let database = try await service.fetch()
          try replaceDatabase(with: database)
          Self.logger.debug("Done updating database")
        } catch is CancellationError {
          Self.logger.debug("Job cancelled")
        } catch {
          Self.logger.warning("Unable to update. Reason: \(error)")
        }
      }
    }

    func replaceDatabase(with database: ClrMameProDatabase) throws {
      let replacement = RomHeaderInformation(database: database)

      do {
        let existingHeaders = try modelContext.fetch(
          FetchDescriptor<RomHeaderInformation>()
        )

        Self.logger.debug("Start deleting previous information")

        for header in existingHeaders {
          modelContext.delete(header)
        }

        Self.logger.debug("Done deleting previous information")

        modelContext.insert(replacement)
        try modelContext.save()

        Self.logger.debug("Saved latest information")
      } catch {
        modelContext.rollback()
        throw error
      }
    }

    func cancel() {
      workerTask?.cancel()
      workerTask = nil
      Self.logger.debug("Running task cancelled")
    }
  }
}
