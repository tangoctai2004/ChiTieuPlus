import SwiftUI
import CoreData
import AVFoundation

struct TransactionAddScreen: View {
    @EnvironmentObject var viewModel: TransactionFormViewModel
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var speechService = SpeechRecognitionService() // <-- THÊM MỚI
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var showSuccessToast = false

    private var canSave: Bool {
        viewModel.canSave
    }

    var body: some View {
        NavigationStack(path: navigationCoordinator.path(for: 3)) {
            ZStack {
                VStack(spacing: 0) {
                    CustomAddHeaderView(
                        selectedType: $viewModel.type,
                        isRecording: speechService.isRecording,
                        recordAction: {
                            viewModel.toggleRecording()
                        }
                    )
                    ScrollView {
                        VStack(spacing: 12) {
                            TransactionFormFields(viewModel: viewModel)
                                .formSectionStyle()
                            CategorySelectionGrid(viewModel: viewModel, categoryVM: categoryVM)
                                .formSectionStyle()
                        }
                        .padding()
                    }
                    Button(action: saveTransaction) {
                        Text(viewModel.type == "expense" ? "add_transaction_button_expense" : "add_transaction_button_income")
                    }
                    .buttonStyle(PrimaryActionButtonStyle(isEnabled: canSave))
                    .disabled(!canSave)
                    .bottomActionBar()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationBarHidden(true)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onTapGesture { hideKeyboard() }
                .onAppear {
                    DispatchQueue.main.async {
                        categoryVM.fetchAllCategories()       // Tải danh mục cho Grid
                        viewModel.loadCategoryData()        // <--- BẮT BUỘC PHẢI CÓ DÒNG NÀY
                        viewModel.setupSpeechService(speechService)
                    }
                }
                
                if showSuccessToast {
                    SuccessToastView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring()) { showSuccessToast = false }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .zIndex(1)
                }
                VStack {
                    Spacer()
                    if speechService.isRecording {
                        RecordingIndicatorView(
                            transcribedText: $speechService.transcribedText,
                            stopAction: {
                                viewModel.toggleRecording()
                            }
                        )
                        // Hiệu ứng trượt từ dưới lên
                        .transition(.move(edge: .bottom))
                        .background(Color(.systemGroupedBackground).ignoresSafeArea())
                    }
                }
                .edgesIgnoringSafeArea(.bottom) // Cho phép pop-up chạy xuống đáy
                .animation(.spring(), value: speechService.isRecording)
                .zIndex(1)
            }
        }
    }
    
    private func saveTransaction() {
        viewModel.save()
        viewModel.reset()
        withAnimation(.spring()) { showSuccessToast = true }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct TransactionFormFields: View {
    @ObservedObject var viewModel: TransactionFormViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("form_title").font(.subheadline).foregroundColor(.primary)
                TextField(String(localized: "form_placeholder_title"), text: $viewModel.transactionTitle)
                    .multilineTextAlignment(.trailing).font(.subheadline)
            }.padding()
            
            Divider().padding(.leading)
            
            HStack {
                Text("form_date").font(.subheadline).foregroundColor(.primary)
                Spacer()
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden()
            }.padding()
            
            Divider().padding(.leading)
            
            HStack {
                Text("form_note").font(.subheadline).foregroundColor(.primary)
                TextField(String(localized: "form_placeholder_note"), text: $viewModel.note)
                    .multilineTextAlignment(.trailing).font(.subheadline)
            }.padding()
            
            Divider().padding(.leading)
            
            HStack {
                Text(viewModel.type == "expense" ? "form_amount_expense" : "form_amount_income")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                TextField("0", text: $viewModel.formattedAmount)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing).font(.subheadline)
                    .foregroundColor(viewModel.type == "expense" ? AppColors.expenseColor : AppColors.incomeColor)
                    .onChange(of: viewModel.formattedAmount) { newValue in
                        let digits = newValue.filter { "0123456789".contains($0) }
                        viewModel.rawAmount = digits
                        viewModel.formattedAmount = AppUtils.formatCurrencyInput(digits)
                    }
                Text(CurrencySettings.shared.currentCurrency.symbol).foregroundColor(.secondary)
            }.padding()
        }
    }
}

struct CategorySelectionGrid: View {
    @ObservedObject var viewModel: TransactionFormViewModel
    @ObservedObject var categoryVM: CategoryViewModel
    @State private var isShowingCategorySheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("form_category")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding([.top, .horizontal])

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(categoryVM.categories.filter { $0.type == viewModel.type }) { category in
                    CategoryGridButton(
                        category: category,
                        isSelected: viewModel.selectedCategoryID == category.objectID
                    ) {
                        viewModel.selectedCategory = category
                        viewModel.selectedCategoryID = category.objectID
                    }
                }
                Button {
                    isShowingCategorySheet = true
                } label: {
                    EditCategoryButton()
                }
            }
            .padding([.horizontal, .bottom])
        }
        .sheet(isPresented: $isShowingCategorySheet) {
            NavigationStack {
                CategoryListScreen(isPresentingModal: true)
            }
        }
    }
}

struct CustomAddHeaderView: View {
    @Binding var selectedType: String
    var isRecording: Bool // Thêm mới
    var recordAction: () -> Void // Thêm mới
    
    var body: some View {
        ZStack {
            // 1. Picker được căn giữa
            HStack {
                Spacer()
                Picker("", selection: $selectedType.animation()) {
                    Text("common_expense").tag("expense")
                    Text("common_income").tag("income")
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                Spacer()
            }
            
            // 2. Nút Micro được căn bên phải
            HStack {
                Spacer()
                Button(action: recordAction) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(isRecording ? .red : .blue)
                        .padding(.trailing)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}

struct CategoryGridButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName ?? "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(IconProvider.color(for: category.iconName))
                Text(LocalizedStringKey(category.name ?? "common_not_available"))
                    .font(.caption2)
                    .foregroundColor(isSelected ? IconProvider.color(for: category.iconName) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 70)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? IconProvider.color(for: category.iconName) : Color.clear, lineWidth: 2)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct EditCategoryButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("common_edit")
                .font(.caption2)
                .foregroundColor(.primary)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 70)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SuccessToastView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(AppColors.incomeColor)
                .symbolEffect(.bounce.down.byLayer, value: true)
            Text("toast_add_success")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(30)
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        .onAppear(perform: playSound)
    }
    
    func playSound() {
        AudioServicesPlaySystemSound(1054)
    }
}

// MARK: - VIEW POP-UP KHI GHI ÂM
struct RecordingIndicatorView: View {
    // Nhận văn bản đang được dịch
    @Binding var transcribedText: String
    // Nhận hành động "Dừng" từ ViewModel
    var stopAction: () -> Void
    
    // Biến @State để tạo hiệu ứng sóng
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Đang lắng nghe...")
                .font(.headline)
                .foregroundColor(.primary)

            // 2. Sóng âm (dùng biểu tượng của Apple và tạo hiệu ứng)
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                // Hiệu ứng lặp đi lặp lại
                .symbolEffect(.variableColor.iterative.reversing,
                              options: .repeating,
                              value: isAnimating)

            // 3. Hiển thị văn bản đang dịch
            Text(transcribedText.isEmpty ? "Mời bạn nói..." : transcribedText)
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)
                .frame(minHeight: 50, alignment: .center)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.2), value: transcribedText)

            // 4. Nút Dừng
            Button(action: stopAction) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .shadow(radius: 5)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 40) // Chừa không gian cho Home Indicator
        .frame(maxWidth: .infinity)
        .background(.thinMaterial) // Hiệu ứng mờ (giống ảnh)
        .cornerRadius(20, corners: [.topLeft, .topRight]) // Bo góc trên
        .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
        .onAppear {
            isAnimating = true
        }
    }
}

// (Bạn có thể đã có extension này từ HomeScreen, nhưng tôi thêm lại cho chắc)
// Extension để bo góc tùy chỉnh
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}
//
//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//    
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        return Path(path.cgPath)
//    }
//}
