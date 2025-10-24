//
//  YearlyCategoryStatisticScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 24/10/25.
//

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
            Text("BIỂU ĐỒ PHÂN TÍCH NĂM \(String(viewModel.selectedYear))")
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
                .annotation(position: .top, alignment: .center) {
                    if dataPoint.totalAmount > (viewModel.totalYearlyAmount / 12) {
                        Text(AppUtils.formattedCurrency(dataPoint.totalAmount))
                            .font(.caption2)
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
                Text("Tổng giao dịch")
                    .font(.headline)
                Spacer()
                Text(AppUtils.formattedCurrency(viewModel.totalYearlyAmount))
                    .font(.headline.bold())
                    .foregroundColor(viewModel.categoryColor)
            }
            Divider()
            HStack {
                Text("Trung bình mỗi tháng")
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
            Section(header: Text("CHI TIẾT HÀNG THÁNG")) {
                ForEach(viewModel.monthlyChartData) { dataPoint in
                    
                    NavigationLink(value: dataPoint) {
                        HStack {
                            Text("Tháng \(dataPoint.month)")
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
                     Text("\(viewModel.categoryName) (\(String(viewModel.selectedYear)))")
                        .font(.headline)
                     Text(AppUtils.formattedCurrency(viewModel.totalYearlyAmount))
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
