import SwiftUI
import CoreData

// MARK: - Transaction Row
struct TransactionRow: View {
    @ObservedObject var transaction: Transaction
    
    // Tự động dịch "key" nếu category.name là key
    private var categoryName: LocalizedStringKey {
        LocalizedStringKey(transaction.category?.name ?? "common_category")
    }
    
    // Tự động dịch "key" nếu transaction.title là key
    private var transactionTitle: LocalizedStringKey {
        LocalizedStringKey(transaction.title ?? "common_no_name")
    }
    
    private var iconName: String {
        IconProvider.color(for: transaction.category?.iconName) == .primary ? "questionmark" : transaction.category?.iconName ?? "questionmark"
    }
    
    private var iconColor: Color {
        IconProvider.color(for: transaction.category?.iconName)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                // Sử dụng transactionTitle đã được bọc LocalizedStringKey
                Text(transactionTitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                // Sử dụng categoryName đã được bọc LocalizedStringKey
                Text(categoryName)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(AppUtils.formattedCurrency(transaction.amount))
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - HomeScreen (Đã tối ưu)
struct HomeScreen: View {
    // 1. Sử dụng @StateObject để quản lý ViewModel (Combine model)
    // Tận dụng việc ViewModel đã được tối ưu để Fetch data trên background thread
    @StateObject private var viewModel = TransactionViewModel()

    @State private var selectedFilter: FilterType = .all
    enum FilterType: String, CaseIterable {
        case all = "filter_all"
        case income = "filter_income"
        case expense = "filter_expense"
        
        var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
    }
    
    // --- Biến Gradient (Giữ nguyên) ---
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.red, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // 2. Tách riêng logic lọc và nhóm ra khỏi `body`
    // Tốc độ phụ thuộc vào số lượng item trong viewModel.allTransactions
    private var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all:
            return viewModel.allTransactions
        case .income:
            return viewModel.allTransactions.filter { $0.type == "income" }
        case .expense:
            return viewModel.allTransactions.filter { $0.type == "expense" }
        }
    }

    // Nhóm theo ngày
    private var groupedTransactions: [(date: Date, items: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date ?? Date())
        }
        // Sắp xếp nhóm theo ngày giảm dần
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, items: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 0) {
                        // --- Header Title (Giữ nguyên) ---
                        VStack(spacing: 0) {
                            (Text("home_title_expense")
                                .foregroundColor(.primary)
                            +
                            Text("+")
                                .foregroundStyle(gradient)
                            )
                            .font(.custom("Bungee-Regular", size: 40))
                            .padding(.top, 13)
                        }
                        
                        // --- Picker (Giữ nguyên) ---
                        Picker("home_filter_picker_label", selection: $selectedFilter.animation(.easeInOut(duration: 0.3))) {
                            ForEach(FilterType.allCases, id: \.self) { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 15)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // --- DANH SÁCH GIAO DỊCH ---
                        // 3. Sử dụng LazyVStack bên trong ScrollView
                        ScrollView {
                            LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) { // Thêm pinnedViews
                                if groupedTransactions.isEmpty {
                                    // --- Phần "Chưa có giao dịch" (Giữ nguyên) ---
                                    VStack(spacing: 12) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 60))
                                            .foregroundColor(.secondary)
                                        Text("home_no_transactions")
                                            .foregroundColor(.secondary)
                                            .font(.title3)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 100)
                                } else {
                                    // 4. Lặp qua các nhóm đã tính toán
                                    ForEach(groupedTransactions, id: \.date) { group in
                                        // Section Header (Đã tối ưu)
                                        Section { // Bọc ForEach con trong Section
                                            ForEach(group.items, id: \.id) { transaction in
                                                NavigationLink {
                                                    TransactionDetailScreen(
                                                        viewModel: TransactionFormViewModel(transaction: transaction)
                                                    )
                                                } label: {
                                                    TransactionRow(transaction: transaction)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        } header: { // Đưa header vào Section
                                            Text(formattedDate(group.date))
                                                .font(.callout.weight(.semibold))
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.vertical, 8) // Thêm padding cho header
                                                .background(Color(.systemGroupedBackground)) // Nền cho header dính
                                                .padding(.leading, 5) // Giữ padding cũ
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                )
            .navigationBarHidden(true)
        }
        .onAppear {
            DispatchQueue.main.async { // <--- Chỉ cần thêm dòng này
                viewModel.fetchTransactions()
            } // <--- Và dòng này
        }
    }
    
    // --- Hàm formattedDate (Giữ nguyên) ---
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Các Extension (Giữ nguyên)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
