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
                    TextField(String(localized: "form_category_name"), text: $name).padding()
                    Divider()
                    // --- SỬA ĐỔI ---
                    Picker("form_type", selection: $selectedType) { // Bỏ Text()
                    // --- KẾT THÚC SỬA ĐỔI ---
                        Text("common_expense").tag("expense")
                        Text("common_income").tag("income")
                    }.pickerStyle(.segmented).padding()
                }
                .formSectionStyle()

                VStack(alignment: .leading) {
                    Text("form_icon").font(.headline).padding([.top, .horizontal])
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                            ForEach(iconList) { iconInfo in
                                IconView(
                                    iconInfo: iconInfo,
                                    isSelected: selectedIconName == iconInfo.iconName
                                )
                                .onTapGesture { selectedIconName = iconInfo.iconName }
                            }
                        }
                        .padding()
                    }
                }
                .formSectionStyle()
                Spacer()
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            Button(action: saveCategoryAction) {
                Text("category_add_save_button")
            }
            .buttonStyle(PrimaryActionButtonStyle(isEnabled: canSave))
            .disabled(!canSave)
            .bottomActionBar()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .addSwipeBackGesture()
    }
    
    private func saveCategoryAction() {
         viewModel.addCategory(name: name, type: selectedType, iconName: selectedIconName)
         dismiss()
    }
}

// MARK: - Custom Header View for Add Screen
struct CustomAddHeader: View {
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            // --- SỬA ĐỔI ---
            Button(action: { onCancel() }) { // Đổi cú pháp Button
                Text("common_cancel")
            }
            // --- KẾT THÚC SỬA ĐỔI ---
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.primary)
            Spacer()
            Text("category_add_title").font(.headline)
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
