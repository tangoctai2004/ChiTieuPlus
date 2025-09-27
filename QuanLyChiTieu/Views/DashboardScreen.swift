import SwiftUI
import CoreData
import Charts

struct DashboardScreen: View {
    @Environment(\.managedObjectContext) private var context
    
    // MARK: - State
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedDay: Date = Date()
    
    // MARK: - Colors
    private let primaryColor = Color.blue
    private let accentColor = Color.green
    private let expenseColor = Color.red
    
    // MARK: - Fetch All Transactions
    @FetchRequest(
        entity: Transaction.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
    ) private var allTransactions: FetchedResults<Transaction>
    
    // MARK: - Filtered Transactions
    private var dailyTransactions: [Transaction] {
        let startOfDay = Calendar.current.startOfDay(for: selectedDay)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return allTransactions.filter { $0.date! >= startOfDay && $0.date! < endOfDay }
    }
    
    private var monthlyTransactions: [Transaction] {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        let startOfMonth = Calendar.current.date(from: comps)!
        let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth)!
        return allTransactions.filter { $0.date! >= startOfMonth && $0.date! < endOfMonth }
    }
    
    // MARK: - Monthly Summary
    private var totalIncome: Double {
        monthlyTransactions.filter { $0.type == "income" }.map(\.amount).reduce(0, +)
    }
    private var totalExpense: Double {
        monthlyTransactions.filter { $0.type == "expense" }.map(\.amount).reduce(0, +)
    }
    private var netBalance: Double { totalIncome - totalExpense }
    
    private var monthlyPieData: [CategorySummary] {
        let grouped = Dictionary(grouping: monthlyTransactions.filter { $0.type == "expense" }) { $0.category?.name ?? "Không rõ" }
        return grouped.map { CategorySummary(name: $0.key, total: $0.value.map(\.amount).reduce(0, +)) }
    }
    
    // MARK: - Daily Summary
    private var dailyIncome: Double {
        dailyTransactions.filter { $0.type == "income" }.map(\.amount).reduce(0, +)
    }
    private var dailyExpense: Double {
        dailyTransactions.filter { $0.type == "expense" }.map(\.amount).reduce(0, +)
    }
    private var dailyNetBalance: Double { dailyIncome - dailyExpense }
    
    private var dailyPieData: [CategorySummary] {
        let grouped = Dictionary(grouping: dailyTransactions.filter { $0.type == "expense" }) { $0.category?.name ?? "Không rõ" }
        return grouped.map { CategorySummary(name: $0.key, total: $0.value.map(\.amount).reduce(0, +)) }
    }
    
    // MARK: - CategorySummary
    struct CategorySummary: Identifiable {
        var id: String { name }
        var name: String
        var total: Double
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: Daily Stats
                    CardView(title: "Thống kê theo ngày") {
                        DatePicker("", selection: $selectedDay, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding(.bottom, 12)
                        
                        StatSummaryView(
                            income: dailyIncome,
                            expense: dailyExpense,
                            netBalance: dailyNetBalance,
                            accentColor: accentColor,
                            expenseColor: expenseColor,
                            primaryColor: primaryColor
                        )
                        
                        if !dailyPieData.isEmpty {
                            PieChartView(data: dailyPieData)
                        }
                    }
                    
                    // MARK: Monthly Stats
                    CardView(title: "Thống kê theo tháng") {
                        HStack(spacing: 16) {
                            Text("Tháng: ")
                            Picker("Tháng", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            
                            Text("Năm: ")
                            Picker("Năm", selection: $selectedYear) {
                                ForEach(2020...2030, id: \.self) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                        
                        StatSummaryView(
                            income: totalIncome,
                            expense: totalExpense,
                            netBalance: netBalance,
                            accentColor: accentColor,
                            expenseColor: expenseColor,
                            primaryColor: primaryColor
                        )
                        
                        if !monthlyPieData.isEmpty {
                            PieChartView(data: monthlyPieData)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Thống Kê Chi Tiêu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Pie Chart View
struct PieChartView: View {
    let data: [DashboardScreen.CategorySummary]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chi Tiêu Theo Danh Mục")
                .font(.subheadline.bold())
            Chart(data) { item in
                SectorMark(angle: .value("Tổng", item.total), innerRadius: .ratio(0.4))
                    .foregroundStyle(by: .value("Danh mục", item.name))
            }
            .frame(height: 260)
        }
        .padding(.top, 8)
    }
}

// MARK: - Statistic Box
struct StatisticBox: View {
    let title: String
    let amount: Double
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.subheadline).bold()
            Text(AppUtils.formattedCurrency(amount))
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let title: String
    let content: () -> Content
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.bold())
                .padding(.bottom, 4)
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Stat Summary View
struct StatSummaryView: View {
    let income: Double
    let expense: Double
    let netBalance: Double
    let accentColor: Color
    let expenseColor: Color
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatisticBox(title: "Thu Nhập", amount: income, color: accentColor)
                StatisticBox(title: "Chi Tiêu", amount: expense, color: expenseColor)
            }
            StatisticBox(title: "Chênh Lệch", amount: netBalance, color: primaryColor)
        }
    }
}
