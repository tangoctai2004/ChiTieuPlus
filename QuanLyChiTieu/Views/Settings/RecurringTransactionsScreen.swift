//
//  RecurringTransactionsScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct RecurringTransactionsScreen: View {
    @StateObject private var viewModel = RecurringTransactionViewModel()
    @State private var isShowingAddRecurring = false
    @State private var recurringToEdit: RecurringTransaction?
    @State private var recurringToDelete: RecurringTransaction?
    @State private var showDeleteAlert = false
    
    var body: some View {
        AppColors.groupedBackground
            .ignoresSafeArea()
            .overlay(
                ScrollView {
                    VStack(spacing: 20) {
                        // Due Transactions Section
                        if !viewModel.dueRecurringTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(NSLocalizedString("recurring_due_title", comment: ""))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.dueRecurringTransactions) { recurring in
                                        RecurringTransactionCardView(
                                            recurring: recurring,
                                            onTap: {
                                                recurringToEdit = recurring
                                            },
                                            onDelete: {
                                                recurringToDelete = recurring
                                                showDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Active Recurring Transactions Section
                        if !viewModel.activeRecurringTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(NSLocalizedString("recurring_active_title", comment: ""))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.activeRecurringTransactions) { recurring in
                                        RecurringTransactionCardView(
                                            recurring: recurring,
                                            onTap: {
                                                recurringToEdit = recurring
                                            },
                                            onDelete: {
                                                recurringToDelete = recurring
                                                showDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Empty State
                        if viewModel.activeRecurringTransactions.isEmpty && viewModel.dueRecurringTransactions.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "repeat.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                Text(NSLocalizedString("recurring_empty_title", comment: ""))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Text(NSLocalizedString("recurring_empty_desc", comment: ""))
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
            .navigationTitle(NSLocalizedString("settings_row_recurring_transactions", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddRecurring = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .tint(.black)
                }
            }
            .sheet(isPresented: $isShowingAddRecurring) {
                RecurringTransactionFormView(
                    recurring: nil,
                    onSave: { title, amount, type, categoryID, frequency, startDate, endDate, note in
                        viewModel.addRecurringTransaction(
                            title: title,
                            amount: amount,
                            type: type,
                            categoryID: categoryID,
                            frequency: frequency,
                            startDate: startDate,
                            endDate: endDate,
                            note: note
                        )
                        isShowingAddRecurring = false
                    }
                )
            }
            .sheet(item: $recurringToEdit) { recurring in
                RecurringTransactionFormView(
                    recurring: recurring,
                    onSave: { title, amount, type, categoryID, frequency, startDate, endDate, note in
                        viewModel.updateRecurringTransaction(
                            recurring,
                            title: title,
                            amount: amount,
                            type: type,
                            categoryID: categoryID,
                            frequency: frequency,
                            startDate: startDate,
                            endDate: endDate,
                            note: note
                        )
                        recurringToEdit = nil
                    }
                )
            }
            .onAppear {
                viewModel.loadRecurringTransactions()
                // Process due transactions when screen appears
                viewModel.processDueTransactions()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecurringTransactionDidChange"))) { _ in
                viewModel.loadRecurringTransactions()
            }
            .alert(NSLocalizedString("recurring_delete_title", comment: ""), isPresented: $showDeleteAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    if let recurring = recurringToDelete {
                        viewModel.deleteRecurringTransaction(recurring)
                        recurringToDelete = nil
                    }
                }
            } message: {
                Text(NSLocalizedString("recurring_delete_message", comment: ""))
            }
    }
}

