import Foundation
import UniformTypeIdentifiers

struct FileMetadata: Identifiable, Comparable {
  let url: URL
  let size: Int64
  let modificationDate: Date?
  let typeDescription: String
  let systemImage: String

  var id: URL { url }
  var name: String { url.lastPathComponent }

  init(url: URL, resourceValues: URLResourceValues) {
    let contentType = resourceValues.contentType

    self.url = url
    size = Int64(resourceValues.fileSize ?? 0)
    modificationDate = resourceValues.contentModificationDate
    typeDescription = contentType?.localizedDescription ?? "File"
    systemImage = Self.systemImage(for: contentType)
  }

  static func < (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
    lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
  }

  private static func systemImage(for contentType: UTType?) -> String {
    guard let contentType else { return "doc" }

    if contentType.conforms(to: .image) {
      return "photo"
    } else if contentType.conforms(to: .audio) {
      return "waveform"
    } else if contentType.conforms(to: .movie) {
      return "film"
    } else if contentType.conforms(to: .archive) {
      return "archivebox"
    } else if contentType.conforms(to: .sourceCode) {
      return "chevron.left.forwardslash.chevron.right"
    } else if contentType.conforms(to: .text) {
      return "doc.text"
    } else {
      return "doc"
    }
  }
}
