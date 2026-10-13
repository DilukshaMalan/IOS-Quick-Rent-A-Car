import SwiftUI

// MARK: - Compact Category Filter (Change 4)
struct CategoryFilterView: View {
    @Binding var selectedCategory: Vehicle.VehicleCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {

                // "All" chip
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(Vehicle.VehicleCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, 2)   // let shadow breathe
        }
    }
}

// MARK: - Single Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .white : Color.fallbackNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.fallbackBlue
                    : Color.gray.opacity(0.10)
            )
            .clipShape(Capsule())
            // Subtle stroke when not selected so chips don't look flat
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.18),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryFilterView(selectedCategory: .constant(.suv))
        .padding(.vertical)
}
