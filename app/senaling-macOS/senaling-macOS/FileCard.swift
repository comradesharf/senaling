import SwiftUI

struct FileCard: View {
  let file: FileMetadata

  var body: some View {
    VStack(alignment: .leading, spacing: AppDesign.cardSpacing) {
      Image(systemName: file.systemImage)
        .font(.title2)
        .foregroundStyle(.tint)
        .frame(width: AppDesign.iconSize, height: AppDesign.iconSize)
        .background(.tint.quinary, in: .rect(cornerRadius: AppDesign.cardCornerRadius / 2))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: AppDesign.cardSpacing / 2) {
        Text(file.name)
          .font(.headline)
          .lineLimit(2)
          .help(file.name)

        LabeledContent("Kind", value: file.typeDescription)

        LabeledContent("Size") {
          Text(file.size, format: .byteCount(style: .file))
        }

        LabeledContent("Modified") {
          if let modificationDate = file.modificationDate {
            Text(modificationDate, format: .dateTime.day().month(.abbreviated).year())
          } else {
            Text("Unknown")
          }
        }
      }
      .font(.subheadline)
    }
    .padding(AppDesign.cardPadding)
    .frame(maxWidth: .infinity, alignment: .leading)
    .modifier(FileCardSurface())
    .accessibilityElement(children: .combine)
  }
}
