import SwiftUI
import Charts
import CoreData

struct MonthlyCategoryStatisticScreen: View {
    @StateObject var viewModel: MonthlyCategoryStatisticViewModel
    @Environment(\.dismiss) var dismiss

    private var typeColor: Color {
        viewModel.categoryColor
    }

    // MARK: - Subviews

    private var chartCardView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("BIỂU ĐỒ PHÂN TÍCH 12 THÁNG")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
                .padding(.bottom, 8)
            
            Chart(viewModel.monthlyChartData) { dataPoint in
                BarMark(
                    x: .value("Tháng", dataPoint.monthLabel),
                    y: .value("Tổng tiền", max(0, dataPoint.totalAmount))
                )
                .foregroundStyle(viewModel.categoryColor)
                .opacity(dataPoint.month == viewModel.selectedChartMonth ? 1.0 : 0.5)
                .annotation(position: .top, alignment: .center) {
                    if dataPoint.totalAmount > 0 {
                        Text(AppUtils.formattedCurrency(dataPoint.totalAmount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
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
            .chartXVisibleDomain(length: 4)
            .chartScrollableAxes(.horizontal)
            .chartXScale(range: .plotDimension(padding: 10))
            .chartScrollPosition(initialX: viewModel.initialMonthLabel)
            .chartGesture { proxy in
                SpatialTapGesture()
                    .onEnded { value in
                        let location = value.location
                        if let monthString: String = proxy.value(atX: location.x, as: String.self),
                           let month = Int(monthString.dropFirst()) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.updateDisplayedTransactions(for: month)
                            }
                        }
                    }
            }
            .scrollIndicators(.hidden)
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 10)
    }

    private var transactionListView: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedDisplayedTransactions, id: \.date) { group in
                    let dailyTotal = group.items.reduce(0) { $0 + ($1.amount.isNaN ? 0 : $1.amount) }
                    let headerView = HStack {
                        Text(viewModel.formattedSectionHeaderDate(group.date))
                        Spacer()
                        Text("(\(AppUtils.formattedCurrency(dailyTotal)))")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))

                    Section(header: headerView) {
                        ForEach(group.items) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionRow(transaction: transaction)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.3), value: viewModel.displayedTransactions)
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
            
            transactionListView
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationDestination(for: Transaction.self) { transaction in
            TransactionDetailScreen(
                viewModel: TransactionFormViewModel(transaction: transaction)
            )
        }
        .navigationTitle(
            "\(viewModel.categoryName) (\(viewModel.selectedPeriodString)) \(AppUtils.formattedCurrency(viewModel.displayedTransactionsTotal))"
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
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

    // MARK: - Helper Functions

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
