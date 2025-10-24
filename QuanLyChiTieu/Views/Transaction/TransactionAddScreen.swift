import SwiftUI
import CoreData
import AVFoundation // Cần cho SuccessToastView

struct TransactionAddScreen: View {
    // ViewModel này thường được inject từ TabView hoặc View cha qua .environmentObject
    @EnvironmentObject var viewModel: TransactionFormViewModel
    // ViewModel riêng để lấy danh sách category
    @StateObject private var categoryVM = CategoryViewModel()
    
    @State private var showSuccessToast = false

    private var canSave: Bool {
        viewModel.canSave
    }

    var body: some View {
        // NavigationStack cần thiết nếu CategoryListScreen được trình bày dạng sheet từ đây
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    CustomAddHeaderView(selectedType: $viewModel.type) // Header tùy chỉnh

                    ScrollView {
                        VStack(spacing: 12) {
                            // Áp dụng style cho các khối con
                            TransactionFormFields(viewModel: viewModel)
                                .formSectionStyle()
                            CategorySelectionGrid(viewModel: viewModel, categoryVM: categoryVM)
                                .formSectionStyle()
                        }
                        .padding() // Padding cho ScrollView
                    }
                    
                    // Nút bấm đã áp dụng style
                    Button(action: saveTransaction) {
                        Text(viewModel.type == "expense" ? "Nhập khoản chi" : "Nhập khoản thu")
                    }
                    .buttonStyle(PrimaryActionButtonStyle(isEnabled: canSave)) // Sử dụng style
                    .disabled(!canSave) // Vẫn cần disabled
                    .bottomActionBar() // Áp dụng style cho Button
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea()) // Nền chung
                .navigationBarHidden(true) // Dùng header tùy chỉnh
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onTapGesture { hideKeyboard() } // Ẩn bàn phím khi chạm ra ngoài
                .onAppear {
                    // Reset ViewModel khi màn hình xuất hiện (quan trọng cho tab Add)
                    // Đảm bảo ViewModel được reset đúng cách nếu nó được chia sẻ qua @EnvironmentObject
                    // Nếu viewModel là @StateObject ở TabView cha, việc reset cần thực hiện ở đó khi tab chuyển đổi
                    // Nếu viewModel được tạo mới mỗi khi tab này xuất hiện thì không cần reset ở đây.
                    // Tạm thời comment dòng reset này nếu viewModel là EnvironmentObject dùng chung.
                    // viewModel.reset()
                    
                    categoryVM.fetchAllCategories() // Luôn tải lại categories
                }
                
                // Toast thông báo thành công
                if showSuccessToast {
                    SuccessToastView()
                        .onAppear {
                            // Tự động ẩn toast sau 1.5 giây
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring()) { showSuccessToast = false }
                            }
                        }
                        // Hiệu ứng xuất hiện/biến mất
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .zIndex(1) // Đảm bảo Toast hiển thị trên cùng
                }
            }
        }
    }
    
    /// Lưu giao dịch hiện tại và reset form
    private func saveTransaction() {
        viewModel.save() // Lưu dữ liệu
        viewModel.reset() // Reset các trường trong ViewModel về trạng thái ban đầu
        withAnimation(.spring()) { showSuccessToast = true } // Hiển thị toast
    }
    
    /// Ẩn bàn phím
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Form Fields (Đã dọn dẹp)
struct TransactionFormFields: View {
    @ObservedObject var viewModel: TransactionFormViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Hàng nhập Tiêu đề
            HStack {
                Text("Tiêu đề").font(.subheadline).foregroundColor(.primary)
                TextField("Nhập tiêu đề (tuỳ chọn)", text: $viewModel.transactionTitle)
                    .multilineTextAlignment(.trailing).font(.subheadline)
            }.padding()
            
            Divider().padding(.leading) // Đường kẻ ngang
            
            // Hàng chọn Ngày
            HStack {
                Text("Ngày").font(.subheadline).foregroundColor(.primary)
                Spacer()
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden() // Ẩn label mặc định của DatePicker
                    .environment(\.locale, Locale(identifier: "vi_VN")) // Đặt locale tiếng Việt
            }.padding()
            
            Divider().padding(.leading)
            
            // Hàng nhập Ghi chú
            HStack {
                Text("Ghi chú").font(.subheadline).foregroundColor(.primary)
                TextField("Nhập ghi chú (tuỳ chọn)", text: $viewModel.note)
                    .multilineTextAlignment(.trailing).font(.subheadline)
            }.padding()
            
            Divider().padding(.leading)
            
            // Hàng nhập Số tiền
            HStack {
                Text(viewModel.type == "expense" ? "Tiền chi" : "Tiền thu").font(.subheadline).foregroundColor(.primary)
                Spacer()
                TextField("0", text: $viewModel.formattedAmount) // Hiển thị số tiền đã định dạng
                    .keyboardType(.numberPad) // Bàn phím số
                    .multilineTextAlignment(.trailing).font(.subheadline)
                    .foregroundColor(viewModel.type == "expense" ? .red : .green) // Màu chữ theo loại
                    .onChange(of: viewModel.formattedAmount) { newValue in
                        // Xử lý khi người dùng nhập: chỉ giữ lại số, cập nhật rawAmount, định dạng lại formattedAmount
                        let digits = newValue.filter { "0123456789".contains($0) }
                        viewModel.rawAmount = digits // Lưu trữ số thô
                        viewModel.formattedAmount = AppUtils.formatCurrencyInput(digits) // Cập nhật hiển thị
                    }
                Text("đ").foregroundColor(.secondary) // Đơn vị tiền tệ
            }.padding()
        }
        // Các modifier nền, cornerRadius đã bị xóa (do áp dụng .formSectionStyle() ở View cha)
    }
}

// MARK: - Category Grid (Đã dọn dẹp và dùng sheet)
struct CategorySelectionGrid: View {
    @ObservedObject var viewModel: TransactionFormViewModel // ViewModel của form chính
    @ObservedObject var categoryVM: CategoryViewModel // ViewModel để lấy danh sách category
    @State private var isShowingCategorySheet = false // State quản lý việc hiển thị sheet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // Thêm spacing
            Text("Danh mục")
                .font(.subheadline)
                .foregroundColor(.primary) // Đảm bảo text rõ ràng
                .padding([.top, .horizontal])

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                // Lọc và hiển thị các category phù hợp với loại giao dịch (chi/thu)
                ForEach(categoryVM.categories.filter { $0.type == viewModel.type }) { category in
                    CategoryGridButton(
                        category: category,
                        isSelected: viewModel.selectedCategoryID == category.objectID // Kiểm tra ID để xác định chọn
                    ) {
                        // Khi nhấn vào một category
                        viewModel.selectedCategory = category // Cập nhật category object (có thể không cần thiết nếu chỉ dùng ID)
                        viewModel.selectedCategoryID = category.objectID // Cập nhật ID được chọn
                    }
                }
                
                // Nút "Chỉnh sửa" để mở sheet danh sách category
                Button {
                    isShowingCategorySheet = true // Kích hoạt sheet
                } label: {
                    EditCategoryButton()
                }
            }
            .padding([.horizontal, .bottom]) // Padding cho lưới
        }
        // Các modifier nền, cornerRadius đã bị xóa (do áp dụng .formSectionStyle() ở View cha)
        .sheet(isPresented: $isShowingCategorySheet) {
            // Nội dung của sheet: CategoryListScreen bọc trong NavigationStack
            NavigationStack {
                // Đảm bảo bạn đã có CategoryListScreen.swift
                CategoryListScreen(isPresentingModal: true) // Truyền cờ để biết đang ở trong sheet
                    // Truyền CategoryViewModel vào nếu cần thiết
                    // .environmentObject(categoryVM) // Ví dụ nếu CategoryListScreen cần
            }
        }
    }
}

// MARK: - Các View phụ khác (Giữ nguyên)

/// Header tùy chỉnh cho màn hình Add
struct CustomAddHeaderView: View {
    @Binding var selectedType: String // Binding để thay đổi loại giao dịch
    var body: some View {
        HStack {
            Spacer() // Đẩy Picker ra giữa
            Picker("", selection: $selectedType.animation()) { // Thêm animation khi đổi
                Text("Tiền chi").tag("expense")
                Text("Tiền thu").tag("income")
            }
            .pickerStyle(.segmented) // Kiểu Segmented Control
            .frame(width: 180) // Cố định chiều rộng
            Spacer() // Đẩy Picker ra giữa
        }
        .padding(.vertical, 10) // Padding trên dưới
        .frame(height: 44) // Chiều cao tiêu chuẩn
        .background(Color(.systemBackground)) // Nền trắng/đen hệ thống
    }
}

/// Nút hiển thị một Category trong lưới
struct CategoryGridButton: View {
    let category: Category // Dữ liệu Category
    let isSelected: Bool // Trạng thái có được chọn hay không
    let action: () -> Void // Hành động khi nhấn nút
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName ?? "questionmark.circle.fill") // Icon
                    .font(.title3)
                    .foregroundColor(IconProvider.color(for: category.iconName)) // Màu icon
                
                Text(category.name ?? "N/A") // Tên Category
                    .font(.caption2) // Font nhỏ
                    // Màu chữ thay đổi dựa trên trạng thái isSelected
                    .foregroundColor(isSelected ? IconProvider.color(for: category.iconName) : .secondary)
                    .lineLimit(2) // Giới hạn 2 dòng
                    .multilineTextAlignment(.center) // Căn giữa nếu 2 dòng
            }
            .frame(width: 80, height: 70) // Kích thước cố định
            .background(Color(.systemGray6)) // Nền xám nhạt
            .cornerRadius(10) // Bo góc
            .overlay( // Viền khi được chọn
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? IconProvider.color(for: category.iconName) : Color.clear, lineWidth: 2)
            )
    
        }
        // Thêm hiệu ứng nhấn nhẹ nếu muốn
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

/// Nút "Chỉnh sửa" trong lưới Category
struct EditCategoryButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Chỉnh sửa")
                .font(.caption2)
                .foregroundColor(.primary)
            Image(systemName: "chevron.right") // Icon mũi tên
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 70) // Kích thước bằng CategoryGridButton
        .background(Color(.systemGray6)) // Nền xám nhạt
        .cornerRadius(10) // Bo góc
    }
}

/// View Toast thông báo thành công
struct SuccessToastView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill") // Icon checkmark
                .font(.system(size: 70))
                .foregroundStyle(.green) // Màu xanh lá
                // Hiệu ứng nảy lên
                .symbolEffect(.bounce.down.byLayer, value: true)

            Text("Thêm giao dịch thành công")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary) // Màu chữ chính
        }
        .padding(30) // Padding lớn xung quanh
        .background(.thinMaterial) // Nền mờ (thay vì ultraThinMaterial)
        .cornerRadius(20) // Bo góc
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5) // Shadow nhẹ
        .onAppear(perform: playSound) // Phát âm thanh khi xuất hiện
    }
    
    /// Phát âm thanh hệ thống (cần import AVFoundation)
    func playSound() {
        // Sử dụng âm thanh mặc định cho thao tác thành công
        AudioServicesPlaySystemSound(1054) // Hoặc thử 1306, 1004 tùy ý
    }
}
