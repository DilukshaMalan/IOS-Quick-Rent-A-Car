import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategory: Vehicle.VehicleCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                // All
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
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .white : Color.fallbackNavy)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(isSelected ? Color.fallbackBlue : Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    CategoryFilterView(selectedCategory: .constant(nil))
}
