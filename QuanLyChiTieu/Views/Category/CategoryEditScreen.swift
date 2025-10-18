import SwiftUI

struct CategoryEditScreen: View {
    @ObservedObject var viewModel: CategoryViewModel
    let category: Category

    @Environment(\.dismiss) private var dismiss

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
            CustomEditHeader(onCancel: { dismiss() })

            ScrollView {
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
                    .background(Color(.systemBackground)) // Giữ nguyên
                    .cornerRadius(10)

                    VStack(alignment: .leading) {
                        Text("Biểu tượng")
                            .font(.headline)
                            .padding([.top, .horizontal])

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
                    .background(Color(.systemBackground)) // Giữ nguyên
                    .cornerRadius(10)
                }
                .padding()
            }

            HStack(spacing: 15) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Xoá")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(25)
                }

                Button(action: {
                    viewModel.updateCategory(category, name: name, type: selectedType, iconName: selectedIconName)
                    dismiss()
                }) {
                    Text("Cập nhật")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray)
                        .cornerRadius(25)
                }
                .disabled(!canSave)
                .opacity(canSave ? 1.0 : 0.6)
            }
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
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear {
            self.name = category.name ?? ""
            self.selectedType = category.type ?? "expense"
            self.selectedIconName = category.iconName ?? ""
        }
        .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
            Button("Chắc chắn xoá", role: .destructive) {
                viewModel.deleteCategory(category)
                dismiss()
            }
            Button("Không", role: .cancel) { }
        } message: {
            Text("Bạn có chắc chắn muốn xoá danh mục \"\(name)\" không?")
        }
    }
}

// MARK: - Custom Header View for Edit Screen
struct CustomEditHeader: View {
    let onCancel: () -> Void

    var body: some View {
        HStack {
            Button("Huỷ") { onCancel() }
                .frame(width: 80, alignment: .leading)
            Spacer()
            Text("Chỉnh sửa danh mục").font(.headline)
            Spacer()
            Spacer().frame(width: 80)
        }
        .padding()
        .frame(height: 44)
        .background(Color(.systemBackground)) // Giữ nguyên
    }
}
