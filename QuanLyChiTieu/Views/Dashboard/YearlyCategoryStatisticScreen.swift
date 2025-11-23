import SwiftUI
import Charts
import CoreData

struct YearlyCategoryStatisticScreen: View {
    @StateObject var viewModel: YearlyCategoryStatisticViewModel
    @Environment(\.dismiss) var dismiss
    
    private var typeColor: Color {
        viewModel.categoryColor
    }

    // MARK: - Subviews

    private var chartCardView: some View {
        VStack(alignment: .center, spacing: 8) {
            // --- SỬA ---
            // Lấy tiêu đề đã dịch từ ViewModel
            Text(viewModel.localizedChartTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
                .padding(.bottom, 8)
            
            Chart(viewModel.monthlyChartData) { dataPoint in
                // Validate totalAmount trước khi truyền vào Chart
                let safeAmount = dataPoint.totalAmount.isFinite && !dataPoint.totalAmount.isNaN && dataPoint.totalAmount >= 0 ? dataPoint.totalAmount : 0
                BarMark(
                    // Trục X (T1.../Jan...) đã được ViewModel xử lý
                    x: .value(Text(NSLocalizedString("common_month_label", comment: "")), dataPoint.monthLabel),
                    y: .value(Text(NSLocalizedString("common_total_amount", comment: "")), safeAmount)
                )
                .foregroundStyle(viewModel.categoryColor)
                .annotation(position: .top, alignment: .center) {
                    let safeTotalYearly = viewModel.totalYearlyAmount.isFinite && !viewModel.totalYearlyAmount.isNaN && viewModel.totalYearlyAmount > 0 ? viewModel.totalYearlyAmount : 1
                    if safeAmount > (safeTotalYearly / 12) {
                        Text(AppUtils.formattedCurrency(safeAmount))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            // ... (Giữ nguyên phần còn lại của biểu đồ) ...
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let amount = value.as(Double.self),
                           amount.isFinite && !amount.isNaN {
                            Text(formatAxisAmount(amount))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
            .chartXVisibleDomain(length: 12)
            .chartScrollableAxes(.horizontal)
            .chartXScale(range: .plotDimension(padding: 10))
            .scrollIndicators(.hidden)
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 10)
    }

    private var summaryInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                // --- SỬA ---
                Text(viewModel.localizedTotalTransactions)
                    .font(.headline)
                Spacer()
                Text(AppUtils.formattedCurrency(viewModel.totalYearlyAmount))
                    .font(.headline.bold())
                    .foregroundColor(viewModel.categoryColor)
            }
            Divider()
            HStack {
                // --- SỬA ---
                Text(viewModel.localizedMonthlyAverage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(AppUtils.formattedCurrency(viewModel.averageMonthlyAmount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var monthSummaryListView: some View {
        List {
            // --- SỬA ---
            Section(header: Text(viewModel.localizedMonthlyDetailHeader)) {
                ForEach(viewModel.monthlyChartData) { dataPoint in
                    
                    NavigationLink(value: dataPoint) {
                        HStack {
                            // --- SỬA ---
                            // Lấy tên tháng đã dịch từ ViewModel
                            Text(viewModel.localizedMonthPrefixes[dataPoint.month] ?? "Month \(dataPoint.month)")
                                .font(dataPoint.totalAmount > 0 ? .headline : .subheadline)
                                .foregroundColor(dataPoint.totalAmount > 0 ? .primary : .secondary)
                            Spacer()
                            Text(AppUtils.formattedCurrency(dataPoint.totalAmount))
                                .font(dataPoint.totalAmount > 0 ? .body.monospacedDigit().bold() : .body.monospacedDigit())
                                .foregroundColor(dataPoint.totalAmount > 0 ? viewModel.categoryColor : .secondary)
                        }
                    }
                    .disabled(dataPoint.totalAmount == 0)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Body
    
    var body: some View {
        
        let backGesture = DragGesture()
            .onEnded { value in
                if value.startLocation.x < 50 && value.translation.width > 100 {
                    withAnimation(.easeInOut) {
                        dismiss()
                    }
                }
            }
        
        VStack(spacing: 0) {
            chartCardView
            
            summaryInfoView
                .padding(.bottom, 10)
            
            monthSummaryListView
        }
        .navigationDestination(for: ChartDataPoint.self) { [viewModel] dataPoint in
            MonthlyCategoryStatisticScreen(
                viewModel: MonthlyCategoryStatisticViewModel(
                    categorySummary: viewModel.categorySummary,
                    selectedMonth: dataPoint.month,
                    selectedYear: viewModel.selectedYear,
                    repository: DataRepository.shared
                )
            )
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
             ToolbarItem(placement: .principal) {
                 VStack {
                     // --- SỬA ---
                     // Lấy tên category đã dịch từ ViewModel
                     Text(viewModel.localizedCategoryName)
                        .font(.headline)
                     Text("(\(String(viewModel.selectedYear))) \(AppUtils.formattedCurrency(viewModel.totalYearlyAmount))")
                        .font(.caption)
                        .foregroundColor(viewModel.categoryColor)
                 }
             }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
            }
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .simultaneousGesture(backGesture)
    }

    // MARK: - Helper Functions (Giữ nguyên)
    private func formatAxisAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1

        if abs(amount) >= 1_000_000 {
            return (formatter.string(from: NSNumber(value: amount / 1_000_000)) ?? "") + "M"
        } else if abs(amount) >= 1_000 {
            formatter.maximumFractionDigits = 0
            return (formatter.string(from: NSNumber(value: amount / 1_000)) ?? "") + "K"
        } else {
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: amount)) ?? ""
        }
    }
}
