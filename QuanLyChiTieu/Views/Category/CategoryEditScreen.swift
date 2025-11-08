import SwiftUI

struct CategoryEditScreen: View {
    @ObservedObject var viewModel: CategoryViewModel
    let category: Category // Giữ nguyên category gốc để sửa

    @Environment(\.dismiss) private var dismiss

    // State cho form
    @State private var name: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedIconName: String = ""
    @State private var showingDeleteConfirmation = false

    let iconList = IconProvider.allIcons

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomEditHeader(onCancel: { dismiss() }) // Header cũ cho nút Huỷ

            ScrollView {
                VStack(spacing: 15) {
                    // Khối Tên & Loại
                    VStack {
                        TextField(String(localized: "form_category_name"), text: $name).padding()
                        Divider()
                        Picker("form_type", selection: $selectedType) { // Đã sửa: Bỏ Text()
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
                }
                .padding()
            }

            HStack(spacing: 15) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("common_delete")
                }
                .buttonStyle(DestructiveActionButtonStyle())

                Button(action: updateCategoryAction) {
                    Text("common_update")
                }
                .buttonStyle(PrimaryActionButtonStyle(isEnabled: canSave))
                .disabled(!canSave)
            }
            .bottomActionBar()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            self.name = category.name ?? ""
            self.selectedType = category.type ?? "expense"
            self.selectedIconName = category.iconName ?? IconProvider.allIcons.first?.iconName ?? ""
        }
        // --- SỬA ĐỔI ---
        .alert(Text("alert_delete_confirmation_title"), isPresented: $showingDeleteConfirmation) {
            Button("alert_button_confirm_delete", role: .destructive) { deleteCategoryAction() } // Bỏ Text()
            Button("alert_button_cancel", role: .cancel) { } // Bỏ Text()
        } message: {
        // --- KẾT THÚC SỬA ĐỔI ---
            Text(String.localizedStringWithFormat(NSLocalizedString("alert_delete_category_message", comment: ""), name))
        }
        .addSwipeBackGesture()
    }
    
    private func updateCategoryAction() {
         viewModel.updateCategory(category, name: name, type: selectedType, iconName: selectedIconName)
         dismiss()
    }
    
    private func deleteCategoryAction() {
         viewModel.deleteCategory(category)
         dismiss()
    }
}

struct CustomEditHeader: View {
    let onCancel: () -> Void
    var body: some View {
        HStack {
            // --- SỬA ĐỔI ---
            Button(action: { onCancel() }) { // Đã sửa: Đổi cú pháp Button
                Text("common_cancel")
            }
            // --- KẾT THÚC SỬA ĐỔI ---
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.primary)
            Spacer()
            Text("category_edit_title").font(.headline)
            Spacer()
            Spacer().frame(width: 80)
        }
        .padding()
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}
