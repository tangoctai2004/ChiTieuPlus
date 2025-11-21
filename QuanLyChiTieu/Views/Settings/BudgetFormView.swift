//
//  BudgetFormView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct BudgetFormView: View {
    let budget: Budget?
    let onSave: (UUID?, Double, BudgetPeriod, Bool) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategoryID: UUID? = nil
    @State private var amount: String = ""
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var rolloverEnabled: Bool = false
    @State private var categories: [Category] = []
    
    private var expenseCategories: [Category] {
        categories.filter { $0.type == "expense" }
    }
    
    init(budget: Budget?, onSave: @escaping (UUID?, Double, BudgetPeriod, Bool) -> Void) {
        self.budget = budget
        self.onSave = onSave
        
        if let budget = budget {
            _selectedCategoryID = State(initialValue: budget.categoryID)
            _amount = State(initialValue: String(format: "%.0f", budget.amount))
            _selectedPeriod = State(initialValue: budget.budgetPeriod)
            _rolloverEnabled = State(initialValue: budget.rolloverEnabled)
        }
    }
    
    private var isValid: Bool {
        !amount.isEmpty && AppUtils.currencyToDouble(amount) > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Danh mục")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            // Option: Total Budget
                            Button(action: {
                                selectedCategoryID = nil
                            }) {
                                HStack {
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(selectedCategoryID == nil ? AppColors.primaryButton : Color.gray.opacity(0.2))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tổng chi tiêu")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("Theo dõi tổng chi tiêu của tất cả danh mục")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedCategoryID == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.primaryButton)
                                    }
                                }
                                .padding(15)
                                .background(AppColors.cardBackground)
                            }
                            
                            Divider()
                            
                            // Category Options
                            ForEach(expenseCategories) { category in
                                Button(action: {
                                    selectedCategoryID = category.id
                                }) {
                                    HStack {
                                        Image(systemName: category.iconName ?? "folder")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedCategoryID == category.id ? .white : .primary)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(selectedCategoryID == category.id ? AppColors.primaryButton : Color.gray.opacity(0.2))
                                            )
                                        
                                        Text(LocalizedStringKey(category.name ?? "common_no_name"))
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedCategoryID == category.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppColors.primaryButton)
                                        }
                                    }
                                    .padding(15)
                                    .background(AppColors.cardBackground)
                                }
                                
                                if category.id != expenseCategories.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Số tiền ngân sách")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("0", text: $amount)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .padding(15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.cardBackground)
                                )
                            
                            Text(CurrencySettings.shared.currentCurrency.symbol)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 15)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Period Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kỳ ngân sách")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Picker("Kỳ", selection: $selectedPeriod) {
                            ForEach(BudgetPeriod.allCases) { period in
                                Text(period.localizedName)
                                    .tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.cardBackground)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Rollover Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Chuyển số dư sang kỳ mới")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Số tiền còn lại sẽ được cộng vào ngân sách kỳ tiếp theo")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $rolloverEnabled)
                                .labelsHidden()
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.cardBackground)
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            .background(AppColors.groupedBackground.ignoresSafeArea())
            .navigationTitle(budget == nil ? "Ngân sách mới" : "Chỉnh sửa ngân sách")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .tint(.black)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        let budgetAmount = AppUtils.currencyToDouble(amount)
                        onSave(selectedCategoryID, budgetAmount, selectedPeriod, rolloverEnabled)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .tint(isValid ? .black : .gray)
                }
            }
            .onAppear {
                DataRepository.shared.fetchCategories()
                // Load categories from publisher
                categories = DataRepository.shared.categoriesPublisher.value
            }
            .onReceive(DataRepository.shared.categoriesPublisher) { newCategories in
                categories = newCategories
            }
        }
    }
}

