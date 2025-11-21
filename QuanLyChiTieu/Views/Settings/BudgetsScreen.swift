//
//  BudgetsScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct BudgetsScreen: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var isShowingAddBudget = false
    @State private var budgetToEdit: Budget?
    @State private var budgetToDelete: Budget?
    @State private var showDeleteAlert = false
    
    var body: some View {
        AppColors.groupedBackground
            .ignoresSafeArea()
            .overlay(
                ScrollView {
                    VStack(spacing: 20) {
                        // Active Budgets Section
                        if !viewModel.activeBudgets.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ngân sách đang hoạt động")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.activeBudgets) { budget in
                                        BudgetCardView(
                                            budget: budget,
                                            onTap: {
                                                budgetToEdit = budget
                                            },
                                            onDelete: {
                                                budgetToDelete = budget
                                                showDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Empty State
                        if viewModel.activeBudgets.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                Text("Chưa có ngân sách")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Text("Tạo ngân sách đầu tiên để theo dõi chi tiêu!")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 100)
                        }
                    }
                    .padding(.bottom, 20)
                }
            )
            .navigationTitle("Ngân sách")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddBudget = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .tint(.black)
                }
            }
            .sheet(isPresented: $isShowingAddBudget) {
                BudgetFormView(
                    budget: nil,
                    onSave: { categoryID, amount, period, rolloverEnabled in
                        viewModel.addBudget(
                            categoryID: categoryID,
                            amount: amount,
                            period: period,
                            rolloverEnabled: rolloverEnabled
                        )
                        isShowingAddBudget = false
                    }
                )
            }
            .sheet(item: $budgetToEdit) { budget in
                BudgetFormView(
                    budget: budget,
                    onSave: { categoryID, amount, period, rolloverEnabled in
                        viewModel.updateBudget(
                            budget,
                            amount: amount,
                            period: period,
                            rolloverEnabled: rolloverEnabled
                        )
                        budgetToEdit = nil
                    }
                )
            }
            .onAppear {
                viewModel.loadBudgets()
                viewModel.updateAllBudgetsSpentAmount()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TransactionDidChange"))) { _ in
                // Update spent amount when transactions change
                viewModel.updateAllBudgetsSpentAmount()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BudgetDidChange"))) { _ in
                // Reload when budgets change
                viewModel.loadBudgets()
            }
            .alert("Xóa ngân sách", isPresented: $showDeleteAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    if let budget = budgetToDelete {
                        viewModel.deleteBudget(budget)
                        budgetToDelete = nil
                    }
                }
            } message: {
                Text("Bạn có chắc muốn xóa ngân sách này? Hành động này không thể hoàn tác.")
            }
    }
}

