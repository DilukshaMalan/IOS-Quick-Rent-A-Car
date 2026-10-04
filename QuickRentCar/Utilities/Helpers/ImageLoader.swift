import SwiftUI

/// Async image loader with caching using SwiftUI's AsyncImage
struct RemoteImageView: View {
    let url: String
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))

            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)

            case .failure:
                Image(systemName: "car.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.gray.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))

            @unknown default:
                EmptyView()
            }
        }
    }
}
