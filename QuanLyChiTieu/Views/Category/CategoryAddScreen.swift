import SwiftUI

// MARK: - Main View
struct CategoryAddScreen: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State để lưu dữ liệu form
    @State private var name: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedIconName: String = IconProvider.allIcons.first?.iconName ?? "cart.fill"
    
    // Lấy danh sách icon từ IconProvider
    let iconList = IconProvider.allIcons
    
    // Điều kiện để bật nút Lưu
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Header
            // SỬA ĐỔI: Header giờ chỉ còn nút Huỷ và tiêu đề
            CustomAddHeader(onCancel: { dismiss() })
            
            // Nội dung chính
            VStack(spacing: 15) {
                // --- Thẻ nhập thông tin ---
                VStack {
                    TextField("Tên danh mục", text: $name)
                        .padding()
                    
                    Divider()
                    
                    Picker("Loại", selection: $selectedType) {
                        Text("Chi tiêu").tag("expense")
                        Text("Thu nhập").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                
                // --- Thẻ chọn biểu tượng ---
                VStack(alignment: .leading) {
                    Text("Biểu tượng")
                        .font(.headline)
                        .padding([.top, .horizontal])
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                            ForEach(iconList) { iconInfo in
                                IconView(
                                    iconInfo: iconInfo,
                                    isSelected: selectedIconName == iconInfo.iconName
                                )
                                .onTapGesture {
                                    selectedIconName = iconInfo.iconName
                                }
                            }
                        }
                        .padding()
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            
            // SỬA ĐỔI: Thêm nút Lưu ở dưới cùng với style mới
            // MARK: - Save Button
            Button(action: {
                viewModel.addCategory(name: name, type: selectedType, iconName: selectedIconName)
                dismiss()
            }) {
                Text("Lưu danh mục")
            }
            .buttonStyle(AnimatedButtonStyle(isEnabled: canSave)) // Áp dụng style hiệu ứng
            .disabled(!canSave)
            .padding()
            .background(Color.white.shadow(radius: 2, y: -2))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
}

// MARK: - Custom Header View for Add Screen
// SỬA ĐỔI: Header chỉ còn nút Huỷ và tiêu đề, không có nút Lưu
struct CustomAddHeader: View {
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Button("Huỷ") {
                onCancel()
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text("Thêm danh mục")
                .font(.headline)
            
            Spacer()
            
            // Placeholder để căn giữa tiêu đề
            Spacer().frame(width: 80)
        }
        .padding()
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}

// MARK: - Icon View
struct IconView: View {
    let iconInfo: IconProvider.IconInfo
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: iconInfo.iconName)
            .font(.title2)
            .foregroundColor(iconInfo.color)
            .frame(width: 50, height: 50)
            .background(
                isSelected ? iconInfo.color.opacity(0.25) : Color(.systemGray6)
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? iconInfo.color : Color.clear, lineWidth: 2)
            )
    }
}
