//
//  SavingsGoalFormView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

struct SavingsGoalFormView: View {
    let goal: SavingsGoal?
    let onSave: (String, Double, Date, String, String) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var targetAmount: String = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var selectedIcon: String = "target"
    @State private var selectedColor: String = "blue"
    
    private let icons = ["target", "star.fill", "heart.fill", "house.fill", "car.fill", "airplane", "gift.fill", "trophy.fill"]
    private let colors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("green", AppColors.incomeColor),
        ("purple", .purple),
        ("orange", .orange),
        ("pink", .pink),
        ("red", AppColors.expenseColor),
        ("teal", .teal),
        ("indigo", .indigo)
    ]
    
    init(goal: SavingsGoal?, onSave: @escaping (String, Double, Date, String, String) -> Void) {
        self.goal = goal
        self.onSave = onSave
        
        if let goal = goal {
            _title = State(initialValue: goal.title ?? "")
            _targetAmount = State(initialValue: String(format: "%.0f", goal.targetAmount))
            _targetDate = State(initialValue: goal.targetDate ?? Date())
            _selectedIcon = State(initialValue: goal.iconName ?? "target")
            _selectedColor = State(initialValue: goal.color ?? "blue")
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !targetAmount.isEmpty && AppUtils.currencyToDouble(targetAmount) > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tên mục tiêu")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        TextField("Ví dụ: Mua xe máy, Du lịch châu Âu...", text: $title)
                            .textFieldStyle(.plain)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Target Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Số tiền mục tiêu")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("0", text: $targetAmount)
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
                    
                    // Target Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ngày hoàn thành mục tiêu")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $targetDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn biểu tượng")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(selectedIcon == icon ? AppColors.primaryButton : Color.gray.opacity(0.2))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn màu")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(colors, id: \.name) { colorItem in
                                Button(action: {
                                    selectedColor = colorItem.name
                                }) {
                                    Circle()
                                        .fill(colorItem.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == colorItem.name ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            .background(AppColors.groupedBackground.ignoresSafeArea())
            .navigationTitle(goal == nil ? "Mục tiêu mới" : "Chỉnh sửa mục tiêu")
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
                        let amount = AppUtils.currencyToDouble(targetAmount)
                        onSave(title, amount, targetDate, selectedIcon, selectedColor)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .tint(isValid ? .black : .gray)
                }
            }
        }
    }
}


