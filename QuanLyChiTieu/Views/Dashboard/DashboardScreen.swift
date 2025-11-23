import SwiftUI
import CoreData
import Charts

struct DashboardScreen: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared

    private let expenseColor = AppColors.expenseColor
    private let incomeColor = AppColors.incomeColor

    @State private var animateChart = false
    @State private var isShowingMonthYearPicker = false
    @State private var isShowingYearPicker = false

    @EnvironmentObject var languageSettings: LanguageSettings
    
    private func triggerChartAnimation() {
        animateChart = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    var body: some View {

        let dragGesture = DragGesture()
            .onEnded { value in
                if value.translation.width > 50 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goToPreviousPeriod()
                        triggerChartAnimation()
                    }
                }
                if value.translation.width < -50 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goToNextPeriod()
                        triggerChartAnimation()
                    }
                }
            }

        let animationTriggerValue = "\(viewModel.periodSelection)-\(viewModel.currentMonthDisplay)-\(viewModel.currentYearDisplay)-\(viewModel.chartTabSelection)"

        NavigationStack(path: navigationCoordinator.path(for: 4)) {
            AppColors.groupedBackground.ignoresSafeArea()
                .overlay(
                    VStack(spacing: 0) {
                        // MARK: - Top Nav
                        HStack {
                            Button(action: {}) { Image(systemName: "magnifyingglass").font(.title3) }.disabled(true).opacity(0)
                            Spacer()
                            Picker("", selection: $viewModel.periodSelection.animation(.easeInOut(duration: 0.3))) {
                                Text("dashboard_period_monthly").tag(0)
                                Text("dashboard_period_yearly").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                            Spacer()
                            Button(action: {}) { Image(systemName: "magnifyingglass").font(.title3).foregroundColor(.primary) }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .frame(height: 44)
                        .background(Color(.systemBackground))

                        // MARK: - Main Content
                        VStack(spacing: 0) {
                            // MARK: - Card Thống kê
                            VStack(spacing: 0) {
                                DateNavigatorView(
                                    displayDate: viewModel.periodSelection == 0 ? viewModel.currentMonthDisplay : viewModel.currentYearDisplay,
                                    onPrevious: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            viewModel.goToPreviousPeriod()
                                            triggerChartAnimation()
                                        }
                                    },
                                    onNext: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            viewModel.goToNextPeriod()
                                            triggerChartAnimation()
                                        }
                                    },
                                    onTapCenter: {
                                        if viewModel.periodSelection == 0 {
                                            isShowingMonthYearPicker = true
                                        } else {
                                            isShowingYearPicker = true
                                        }
                                    }
                                )
                                .padding(.top, 12)

                                SummaryCardView(
                                    income: viewModel.periodSelection == 0 ? viewModel.totalMonthlyIncome : viewModel.totalYearlyIncome,
                                    expense: viewModel.periodSelection == 0 ? viewModel.totalMonthlyExpense : viewModel.totalYearlyExpense,
                                    netBalance: viewModel.periodSelection == 0 ? viewModel.netMonthlyBalance : viewModel.netYearlyBalance,
                                    incomeColor: incomeColor,
                                    expenseColor: expenseColor
                                )
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                // MARK: - Budget Warnings
                                if !budgetViewModel.warningBudgets.isEmpty || !budgetViewModel.exceededBudgets.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if !budgetViewModel.exceededBudgets.isEmpty {
                                            ForEach(budgetViewModel.exceededBudgets.prefix(2)) { budget in
                                                BudgetWarningCard(budget: budget)
                                            }
                                        }
                                        if !budgetViewModel.warningBudgets.isEmpty {
                                            ForEach(budgetViewModel.warningBudgets.prefix(2)) { budget in
                                                BudgetWarningCard(budget: budget)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                }

                                Picker("", selection: $viewModel.chartTabSelection.animation(.easeInOut(duration: 0.3))) {
                                    Text("common_expense").tag(0)
                                    Text("common_income").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                .padding(.top, 16)

                                // Chọn biểu đồ
                                if viewModel.periodSelection == 0 {
                                    if viewModel.chartTabSelection == 0 {
                                        PieChartView(data: viewModel.monthlyExpensePieData, animateChart: animateChart)
                                    } else {
                                        PieChartView(data: viewModel.monthlyIncomePieData, animateChart: animateChart)
                                    }
                                } else {
                                    if viewModel.chartTabSelection == 0 {
                                        PieChartView(data: viewModel.yearlyExpensePieData, animateChart: animateChart)
                                    } else {
                                        PieChartView(data: viewModel.yearlyIncomePieData, animateChart: animateChart)
                                    }
                                }
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(20)
                            .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 10)

                            // MARK: - Danh sách chi tiết
                            let transactionsForPeriod = viewModel.periodSelection == 0 ? viewModel.monthlyTransactions : viewModel.yearlyTransactions

                            if viewModel.periodSelection == 0 {
                                if viewModel.chartTabSelection == 0 {
                                    DataDisplayView(
                                        categoryData: viewModel.monthlyExpensePieData,
                                        transactionsInPeriod: transactionsForPeriod,
                                        listTypeColor: expenseColor,
                                        animationTrigger: animationTriggerValue
                                    )
                                } else {
                                    DataDisplayView(
                                        categoryData: viewModel.monthlyIncomePieData,
                                        transactionsInPeriod: transactionsForPeriod,
                                        listTypeColor: incomeColor,
                                        animationTrigger: animationTriggerValue
                                    )
                                }
                            } else {
                                if viewModel.chartTabSelection == 0 {
                                    DataDisplayView(
                                        categoryData: viewModel.yearlyExpensePieData,
                                        transactionsInPeriod: transactionsForPeriod,
                                        listTypeColor: expenseColor,
                                        animationTrigger: animationTriggerValue
                                    )
                                } else {
                                    DataDisplayView(
                                        categoryData: viewModel.yearlyIncomePieData,
                                        transactionsInPeriod: transactionsForPeriod,
                                        listTypeColor: incomeColor,
                                        animationTrigger: animationTriggerValue
                                    )
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        .gesture(dragGesture)
                    }
                    .navigationDestination(for: CategorySummary.self) { categorySummary in
                        
                        if viewModel.periodSelection == 0 {
                            MonthlyCategoryStatisticScreen(
                                viewModel: MonthlyCategoryStatisticViewModel(
                                    categorySummary: categorySummary,
                                    selectedMonth: viewModel.selectedMonth,
                                    selectedYear: viewModel.selectedYear,
                                    repository: DataRepository.shared
                                )
                            )
                        } else {
                            YearlyCategoryStatisticScreen(
                                viewModel: YearlyCategoryStatisticViewModel(
                                    categorySummary: categorySummary,
                                    selectedYear: viewModel.selectedYear,
                                    repository: DataRepository.shared
                                )
                            )
                        }
                    }
                    .onChange(of: viewModel.periodSelection) { _ in
                        triggerChartAnimation()
                    }
                )
                .onAppear {
                    // Refresh data ngay lập tức để đảm bảo UI được cập nhật
                    viewModel.refreshData()
                    budgetViewModel.loadBudgets()
                    
                    // Delay một chút trước khi update spent amount để đảm bảo budgets đã load xong
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        budgetViewModel.updateAllBudgetsSpentAmount()
                    }
                    triggerChartAnimation()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TransactionDidChange"))) { _ in
                    // Debounce updates để tránh multiple updates trong cùng frame
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        budgetViewModel.updateAllBudgetsSpentAmount()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BudgetDidChange"))) { _ in
                    // Debounce updates để tránh multiple updates trong cùng frame
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        budgetViewModel.loadBudgets()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PopToRoot"))) { notification in
                    if let tab = notification.userInfo?["tab"] as? Int, tab == 4 {
                        // Sử dụng async để tránh update trong cùng frame
                        DispatchQueue.main.async {
                            navigationCoordinator.popToRoot(for: 4)
                        }
                    }
                }
                .sheet(isPresented: $isShowingMonthYearPicker) {
                    MonthYearPickerView(
                        selectedMonth: $viewModel.selectedMonth,
                        selectedYear: $viewModel.selectedYear
                    )
                }
                .sheet(isPresented: $isShowingYearPicker) {
                    YearPickerView(
                        selectedYear: $viewModel.selectedYear
                    )
                }
        }
    }
}

// MARK: - Data Display View
struct DataDisplayView: View {
    let categoryData: [CategorySummary]
    let transactionsInPeriod: [Transaction]
    let listTypeColor: Color
    let animationTrigger: String

    var body: some View {
        Group {
            if !categoryData.isEmpty {
                ScrollView {
                    CategorySummaryListView(
                        data: categoryData,
                        transactionsInPeriod: transactionsInPeriod,
                        typeColor: listTypeColor
                    )
                    .padding(.horizontal)
                    .padding(.top, 18)
                    .padding(.bottom, 80)
                }
                .transition(.opacity)
            } else {
                VStack {
                    Text("common_no_data")
                        .padding(.top, 50)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: animationTrigger)
        .allowsHitTesting(true)
    }
}


// MARK: - Date Navigator View
struct DateNavigatorView: View {
    let displayDate: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onTapCenter: () -> Void
    
    @EnvironmentObject var languageSettings: LanguageSettings

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            Spacer()
            Button(action: onTapCenter) {
                Text(displayDate)
                    .font(.headline)
            }
            .foregroundColor(.primary)
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Summary Card View
struct SummaryCardView: View {
    let income: Double
    let expense: Double
    let netBalance: Double
    let incomeColor: Color
    let expenseColor: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                SummaryItem(title: "common_expense", amount: expense, isExpense: true, color: expenseColor)
                Spacer()
                SummaryItem(title: "common_income", amount: income, isExpense: false, color: incomeColor, alignment: .trailing)
            }
            Divider()
            HStack {
                Text("dashboard_net_balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(AppUtils.formattedCurrency(abs(netBalance)))
                    .font(.headline.bold())
                    .foregroundColor(netBalance >= 0 ? AppColors.incomeColor : AppColors.expenseColor)
            }
        }
        .padding()
    }

    struct SummaryItem: View {
        var title: LocalizedStringKey
        var amount: Double
        var isExpense: Bool
        var color: Color
        var alignment: HorizontalAlignment = .leading

        var body: some View {
            VStack(alignment: alignment, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                // Hiển thị số dương, không cần dấu trừ vì màu đã thể hiện là expense
                Text(AppUtils.formattedCurrency(amount))
                    .font(.headline.bold())
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - Pie Chart View
struct PieChartView: View {
    let data: [CategorySummary]
    let animateChart: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(data) { item in
                // Validate total trước khi truyền vào Chart
                let safeTotal = item.total.isFinite && !item.total.isNaN && item.total >= 0 ? item.total : 0
                SectorMark(
                    angle: .value(Text("common_total_amount"), safeTotal),
                    innerRadius: .ratio(0.5)
                )
                .foregroundStyle(item.color)
            }
            .frame(height: 180)
            .animation(.easeInOut(duration: 1.0), value: animateChart)
            .padding()
        }
        .animation(.easeInOut(duration: 0.3), value: data)
    }
}

// MARK: - Category Summary List View
struct CategorySummaryListView: View {
    let data: [CategorySummary]
    let transactionsInPeriod: [Transaction]
    let typeColor: Color

    var body: some View {
        LazyVStack(spacing: 18) {
            ForEach(data) { item in
                NavigationLink(value: item) {
                    CategorySummaryRow(item: item, typeColor: typeColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Category Summary Row
struct CategorySummaryRow: View {
    let item: CategorySummary
    let typeColor: Color
    
    private var percentageText: String {
        // Validate percentage trước khi format
        let safePercentage = item.percentage.isFinite && !item.percentage.isNaN ? item.percentage : 0
        let percentageValue = safePercentage * 100
        // Validate kết quả nhân
        if percentageValue.isFinite && !percentageValue.isNaN {
            return String(format: "%.1f%%", percentageValue)
        }
        return "0.0%"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.iconName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .foregroundColor(item.color)
                .background(item.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                // Dịch tên Category Summary
                Text(LocalizedStringKey(item.name))
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
            
                Text(percentageText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(AppUtils.formattedCurrency(item.total))
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(typeColor)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
}


// MARK: - Picker Sheet Views
struct MonthYearPickerView: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) { Text("common_skip") }
                Spacer()
                Button(action: { dismiss() }) { Text("alert_button_ok") }
            }
            .padding()

            HStack {
                Picker("common_month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(String.localizedStringWithFormat(NSLocalizedString("common_month_prefix", comment: ""), "\(month)")).tag(month)
                    }
                }
                .pickerStyle(.wheel)

                Picker("common_year", selection: $selectedYear) {
                    ForEach(2020...2030, id: \.self) { year in
                        Text(String(format: "%d", year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .presentationDetents([.height(300)])
    }
}

struct YearPickerView: View {
    @Binding var selectedYear: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) { Text("common_skip") }
                Spacer()
                Button(action: { dismiss() }) { Text("alert_button_ok") }
            }
            .padding()

            Picker("common_year", selection: $selectedYear) {
                ForEach(2020...2030, id: \.self) { year in
                    Text(String(format: "%d", year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .presentationDetents([.height(300)])
    }
}
