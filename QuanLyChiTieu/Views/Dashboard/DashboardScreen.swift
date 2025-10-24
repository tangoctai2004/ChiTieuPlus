//
//  DashboardScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 23/10/25.
//

import SwiftUI
import CoreData
import Charts

struct DashboardScreen: View {
    @StateObject private var viewModel = DashboardViewModel()

    private let expenseColor = Color.red
    private let incomeColor = Color.green

    @State private var animateChart = false
    @State private var isShowingMonthYearPicker = false
    @State private var isShowingYearPicker = false

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
                if value.translation.width > 50 { // Lướt phải
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goToPreviousPeriod()
                        triggerChartAnimation()
                    }
                }
                if value.translation.width < -50 { // Lướt trái
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goToNextPeriod()
                        triggerChartAnimation()
                    }
                }
            }

        let animationTriggerValue = "\(viewModel.periodSelection)-\(viewModel.currentMonthDisplay)-\(viewModel.currentYearDisplay)-\(viewModel.chartTabSelection)"

        NavigationStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
                .overlay(
                    VStack(spacing: 0) {
                        // MARK: - Top Nav
                        HStack {
                            Button(action: {}) { Image(systemName: "magnifyingglass").font(.title3) }.disabled(true).opacity(0) // Nút ẩn để căn giữa
                            Spacer()
                            Picker("", selection: $viewModel.periodSelection.animation(.easeInOut(duration: 0.3))) {
                                Text("Hàng Tháng").tag(0)
                                Text("Hàng Năm").tag(1)
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
                            // MARK: - Card Thống kê (Biểu đồ + Tổng)
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

                                Picker("", selection: $viewModel.chartTabSelection.animation(.easeInOut(duration: 0.3))) {
                                    Text("Chi tiêu").tag(0)
                                    Text("Thu nhập").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                .padding(.top, 16)

                                // Chọn biểu đồ dựa trên cả periodSelection và chartTabSelection
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
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
                    // !!! QUAN TRỌNG: ĐIỂM THAY ĐỔI LỚN LÀ Ở ĐÂY !!!
                    // Cập nhật navigationDestination để kiểm tra periodSelection
                    .navigationDestination(for: CategorySummary.self) { categorySummary in
                        
                        if viewModel.periodSelection == 0 {
                            // Điều hướng tới màn hình chi tiết THÁNG
                            MonthlyCategoryStatisticScreen(
                                viewModel: MonthlyCategoryStatisticViewModel(
                                    categorySummary: categorySummary,
                                    selectedMonth: viewModel.selectedMonth,
                                    selectedYear: viewModel.selectedYear,
                                    repository: DataRepository.shared
                                )
                            )
                        } else {
                            // Điều hướng tới màn hình chi tiết NĂM
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
                    viewModel.refreshData()
                    triggerChartAnimation()
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
                    Text("Không có dữ liệu.")
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
                    .frame(minWidth: 100)
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
                SummaryItem(title: "Chi tiêu", amount: -expense, color: expenseColor)
                Spacer()
                SummaryItem(title: "Thu nhập", amount: income, color: incomeColor, alignment: .trailing)
            }
            Divider()
            HStack {
                Text("Thu chi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(AppUtils.formattedCurrency(netBalance))
                    .font(.headline.bold())
                    .foregroundColor(netBalance >= 0 ? .green : .red)
            }
        }
        .padding()
    }

    struct SummaryItem: View {
        var title: String
        var amount: Double
        var color: Color
        var alignment: HorizontalAlignment = .leading

        var body: some View {
            VStack(alignment: alignment, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                SectorMark(
                    angle: .value("Tổng", item.total),
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

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.iconName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .foregroundColor(item.color)
                .background(item.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
            
                Text(String(format: "%.1f%%", item.percentage * 100))
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
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
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
                Button("Bỏ qua") { dismiss() }
                Spacer()
                Button("OK") { dismiss() }
            }
            .padding()

            HStack {
                Picker("Tháng", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text("tháng \(month)").tag(month)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Năm", selection: $selectedYear) {
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
                Button("Bỏ qua") { dismiss() }
                Spacer()
                Button("OK") { dismiss() }
            }
            .padding()

            Picker("Năm", selection: $selectedYear) {
                ForEach(2020...2030, id: \.self) { year in
                    Text(String(format: "%d", year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .presentationDetents([.height(300)])
    }
}
