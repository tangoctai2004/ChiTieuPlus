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
                        TextField("Tên danh mục", text: $name).padding()
                        Divider()
                        Picker("Loại", selection: $selectedType) {
                            Text("Chi tiêu").tag("expense")
                            Text("Thu nhập").tag("income")
                        }.pickerStyle(.segmented).padding()
                    }
                    .formSectionStyle()

                    VStack(alignment: .leading) {
                        Text("Biểu tượng").font(.headline).padding([.top, .horizontal])
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
                    Text("Xoá")
                }
                .buttonStyle(DestructiveActionButtonStyle())

                Button(action: updateCategoryAction) {
                    Text("Cập nhật")
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
        .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
            Button("Chắc chắn xoá", role: .destructive) { deleteCategoryAction() }
            Button("Không", role: .cancel) { }
        } message: {
            Text("Bạn có chắc chắn muốn xoá danh mục \"\(name)\" không?")
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
            Button("Huỷ") { onCancel() }
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.primary)
            Spacer()
            Text("Chỉnh sửa danh mục").font(.headline)
            Spacer()
            Spacer().frame(width: 80)
        }
        .padding()
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}
