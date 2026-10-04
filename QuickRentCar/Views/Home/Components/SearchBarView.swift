import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var pickupLocation: String

    var body: some View {
        VStack(spacing: .spacingS) {
            // Location row
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.fallbackBlue)
                TextField("Pickup location", text: $pickupLocation)
                    .font(.subheadline)
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))

            // Search row
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search vehicles...", text: $searchText)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
        }
    }
}

#Preview {
    SearchBarView(searchText: .constant(""), pickupLocation: .constant(""))
        .padding()
}
