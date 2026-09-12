import SwiftUI

struct FileGrid: View {
  let files: [FileMetadata]

  private let columns = [
    GridItem(.adaptive(minimum: AppDesign.minimumCardWidth), spacing: AppDesign.cardSpacing)
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, alignment: .leading, spacing: AppDesign.cardSpacing) {
        ForEach(files) { file in
          FileCard(file: file)
        }
      }
      .padding(.bottom, AppDesign.pagePadding)
    }
    .scrollIndicators(.hidden)
  }
}
