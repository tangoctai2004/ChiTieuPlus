import SwiftUI
import CoreData

// MARK: - Transaction Row (Giữ nguyên)
struct TransactionRow: View {
    @ObservedObject var transaction: Transaction
    
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
                Text(transaction.title ?? "Không tên")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(transaction.category?.name ?? "Danh mục")
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

// MARK: - HomeScreen (ĐÃ CẬP NHẬT)
struct HomeScreen: View {
    @StateObject private var viewModel = TransactionViewModel()
    
    @State private var selectedFilter: FilterType = .all
    enum FilterType: String, CaseIterable {
        case all = "Tất cả"
        case income = "Thu nhập"
        case expense = "Chi tiêu"
    }
    
    // --- TẠO BIẾN GRADIENT ---
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [.red, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        NavigationStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            VStack(spacing: 0) {
                                // --- THAY ĐỔI Ở ĐÂY ---
                                (Text("CHI TIÊU")
                                    .foregroundColor(.primary)
                                +
                                Text("+")
                                    .foregroundStyle(gradient)
                                )
                                .font(.custom("Bungee-Regular", size: 40))
                                .padding(.top, 13)
                                // --- KẾT THÚC THAY ĐỔI ---
                            }
                        }
    
                        Picker("Lọc giao dịch", selection: $selectedFilter.animation(.easeInOut(duration: 0.3))) {
                            ForEach(FilterType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
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
                        ScrollView {
                            VStack(spacing: 18) {
                                if filteredTransactions().isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 60))
                                            .foregroundColor(.secondary)
                                        Text("Chưa có giao dịch")
                                            .foregroundColor(.secondary)
                                            .font(.title3)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 100)
                                } else {
                                    ForEach(groupedFilteredTransactions(), id: \.date) { group in
                                        Text(formattedDate(group.date))
                                            .font(.callout.weight(.semibold))
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 15)
                                            .padding(.leading, 5)
                                        
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
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .animation(.easeOut(duration: 0.4), value: filteredTransactions())
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                )
            .navigationBarHidden(true)
        }
    }
    
    // --- CÁC HÀM LOGIC GIỮ NGUYÊN 100% ---
    
    private func filteredTransactions() -> [Transaction] {
        switch selectedFilter {
        case .all:
            return viewModel.allTransactions
        case .income:
            return viewModel.allTransactions.filter { $0.type == "income" }
        case .expense:
            return viewModel.allTransactions.filter { $0.type == "expense" }
        }
    }
    
    private func groupedFilteredTransactions() -> [(date: Date, items: [Transaction])] {
        let filtered = filteredTransactions()
        let groupDict = Dictionary(grouping: filtered) { transaction in
            Calendar.current.startOfDay(for: transaction.date ?? Date())
        }
        return groupDict.map { (key, value) in
            (date: key, items: value)
        }.sorted { $0.date > $1.date }
    }
    
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
