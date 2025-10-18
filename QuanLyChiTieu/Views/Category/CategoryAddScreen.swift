import SwiftUI

struct CategoryAddScreen: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedIconName: String = IconProvider.allIcons.first?.iconName ?? "cart.fill"
    
    let iconList = IconProvider.allIcons
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomAddHeader(onCancel: { dismiss() })
            
            VStack(spacing: 15) {
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
                .background(Color(.systemBackground)) // Giữ nguyên, đã hỗ trợ
                .cornerRadius(10)
                
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
                .background(Color(.systemBackground)) // Giữ nguyên, đã hỗ trợ
                .cornerRadius(10)
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            
            Button(action: {
                viewModel.addCategory(name: name, type: selectedType, iconName: selectedIconName)
                dismiss()
            }) {
                Text("Lưu danh mục")
            }
            .buttonStyle(AnimatedButtonStyle(isEnabled: canSave))
            .disabled(!canSave)
            .padding()
            .background(
                Color(.systemGroupedBackground)
                    .shadow(
                        color: Color.primary.opacity(0.1),
                        radius: 2,
                        x: 0,
                        y: -2
                    )
            )
            .padding(.bottom, 35)
        }
        .background(Color(.systemGroupedBackground)) // Giữ nguyên, đã hỗ trợ
        .navigationBarHidden(true)
    }
}

// MARK: - Custom Header View for Add Screen
struct CustomAddHeader: View {
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Button("Huỷ") { onCancel() }
                .frame(width: 80, alignment: .leading)
            Spacer()
            Text("Thêm danh mục").font(.headline)
            Spacer()
            Spacer().frame(width: 80)
        }
        .padding()
        .frame(height: 44)
        .background(Color(.systemBackground)) // Giữ nguyên, đã hỗ trợ
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
                isSelected ? iconInfo.color.opacity(0.25) : Color(.systemGray6) // systemGray6 đã hỗ trợ
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? iconInfo.color : Color.clear, lineWidth: 2)
            )
    }
}
