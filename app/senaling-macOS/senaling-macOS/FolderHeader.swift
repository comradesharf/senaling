import SwiftUI

struct FolderHeader: View {
  let folderName: String?
  let fileCount: Int
  let chooseFolder: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: AppDesign.sectionSpacing) {
      VStack(alignment: .leading) {
        Text(folderName ?? "Your files")
          .font(.largeTitle)
          .bold()
          .lineLimit(1)

        if folderName != nil {
          Text("^[\(fileCount) file](inflect: true)")
            .foregroundStyle(.secondary)
        } else {
          Text("Browse a folder and inspect its contents at a glance.")
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if folderName != nil {
        ChooseFolderButton(action: chooseFolder)
      }
    }
  }
}

#Preview {
  FolderHeader(
    folderName: nil,
    fileCount: 0,
    chooseFolder: {}
  )
}
