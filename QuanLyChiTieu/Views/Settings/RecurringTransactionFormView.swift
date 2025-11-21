//
//  RecurringTransactionFormView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct RecurringTransactionFormView: View {
    let recurring: RecurringTransaction?
    let onSave: (String, Double, String, UUID?, RecurringFrequency, Date, Date?, String?) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedCategoryID: UUID? = nil
    @State private var selectedFrequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var hasEndDate: Bool = false
    @State private var note: String = ""
    @State private var categories: [Category] = []
    
    private var expenseCategories: [Category] {
        categories.filter { $0.type == "expense" }
    }
    
    private var incomeCategories: [Category] {
        categories.filter { $0.type == "income" }
    }
    
    private var availableCategories: [Category] {
        selectedType == "expense" ? expenseCategories : incomeCategories
    }
    
    init(recurring: RecurringTransaction?, onSave: @escaping (String, Double, String, UUID?, RecurringFrequency, Date, Date?, String?) -> Void) {
        self.recurring = recurring
        self.onSave = onSave
        
        if let recurring = recurring {
            _title = State(initialValue: recurring.title ?? "")
            _amount = State(initialValue: String(format: "%.0f", recurring.amount))
            _selectedType = State(initialValue: recurring.type ?? "expense")
            _selectedCategoryID = State(initialValue: recurring.categoryID)
            _selectedFrequency = State(initialValue: recurring.transactionFrequency)
            _startDate = State(initialValue: recurring.startDate ?? Date())
            _endDate = State(initialValue: recurring.endDate)
            _hasEndDate = State(initialValue: recurring.endDate != nil)
            _note = State(initialValue: recurring.note ?? "")
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !amount.isEmpty && AppUtils.currencyToDouble(amount) > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_title_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        TextField("Ví dụ: Tiền lương, Tiền thuê nhà...", text: $title)
                            .textFieldStyle(.plain)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Type Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_type_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Picker("Loại", selection: $selectedType) {
                            Text("common_expense").tag("expense")
                            Text("common_income").tag("income")
                        }
                        .pickerStyle(.segmented)
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.cardBackground)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_amount_label", comment: ""))
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
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_category_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        if availableCategories.isEmpty {
                            Text("Chưa có danh mục \(selectedType == "expense" ? "chi tiêu" : "thu nhập")")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Option: No Category
                                    Button(action: {
                                        selectedCategoryID = nil
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "xmark.circle")
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedCategoryID == nil ? .white : .secondary)
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    Circle()
                                                        .fill(selectedCategoryID == nil ? AppColors.primaryButton : Color.gray.opacity(0.2))
                                                )
                                            
                                            Text("Không có")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    ForEach(availableCategories) { category in
                                        Button(action: {
                                            selectedCategoryID = category.id
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: category.iconName ?? "folder")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(selectedCategoryID == category.id ? .white : .primary)
                                                    .frame(width: 50, height: 50)
                                                    .background(
                                                        Circle()
                                                            .fill(selectedCategoryID == category.id ? AppColors.primaryButton : Color.gray.opacity(0.2))
                                                    )
                                                
                                                Text(LocalizedStringKey(category.name ?? "common_no_name"))
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 60)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Frequency Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_frequency_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Picker("Tần suất", selection: $selectedFrequency) {
                            ForEach(RecurringFrequency.allCases) { frequency in
                                Text(frequency.localizedName)
                                    .tag(frequency)
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
                    
                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_start_date_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                    .padding(.horizontal)
                    
                    // End Date Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("recurring_has_end_date_label", comment: ""))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(NSLocalizedString("recurring_has_end_date_desc", comment: ""))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $hasEndDate)
                                .labelsHidden()
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.cardBackground)
                        )
                    }
                    .padding(.horizontal)
                    
                    // End Date (if enabled)
                    if hasEndDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("recurring_end_date_label", comment: ""))
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("recurring_note_label", comment: ""))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        TextField("Nhập ghi chú...", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...6)
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
            .navigationTitle(recurring == nil ? NSLocalizedString("recurring_new_title", comment: "") : NSLocalizedString("recurring_edit_title", comment: ""))
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
                        let transactionAmount = AppUtils.currencyToDouble(amount)
                        onSave(title, transactionAmount, selectedType, selectedCategoryID, selectedFrequency, startDate, hasEndDate ? endDate : nil, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .tint(isValid ? .black : .gray)
                }
            }
            .onAppear {
                DataRepository.shared.fetchCategories()
                categories = DataRepository.shared.categoriesPublisher.value
            }
            .onReceive(DataRepository.shared.categoriesPublisher) { newCategories in
                categories = newCategories
            }
        }
    }
}

