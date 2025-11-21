//
//  SavingsGoalViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import Foundation
import SwiftUI
import Combine

class SavingsGoalViewModel: ObservableObject {
    @Published var savingsGoals: [SavingsGoal] = []
    @Published var isLoading = false
    
    private let repository = DataRepository.shared
    
    init() {
        loadSavingsGoals()
        updateAllGoalsProgress()
    }
    
    func loadSavingsGoals() {
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.savingsGoals = self.repository.fetchSavingsGoals()
            self.isLoading = false
        }
    }
    
    func updateAllGoalsProgress() {
        let goals = repository.fetchSavingsGoals()
        
        for goal in goals {
            let currentSavings = repository.calculateTotalSavings(from: goal.startDate)
            print("📊 Mục tiêu: \(goal.title ?? "")")
            print("   - Ngày bắt đầu: \(goal.startDate?.description ?? "không có")")
            print("   - Tiết kiệm hiện tại: \(currentSavings)")
            print("   - Mục tiêu: \(goal.targetAmount)")
            print("   - Tiến độ: \(Int((currentSavings / goal.targetAmount) * 100))%")
            repository.updateSavingsGoalProgress(goal, amount: currentSavings)
        }
        loadSavingsGoals()
    }
    
    func addGoal(
        title: String,
        targetAmount: Double,
        targetDate: Date,
        iconName: String = "target",
        color: String = "blue"
    ) {
        repository.addSavingsGoal(
            title: title,
            targetAmount: targetAmount,
            targetDate: targetDate,
            iconName: iconName,
            color: color
        )
        loadSavingsGoals()
        // Update progress after loading goals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateAllGoalsProgress()
        }
    }
    
    func updateGoal(
        _ goal: SavingsGoal,
        title: String,
        targetAmount: Double,
        targetDate: Date,
        iconName: String? = nil,
        color: String? = nil
    ) {
        repository.updateSavingsGoal(
            goal,
            title: title,
            targetAmount: targetAmount,
            targetDate: targetDate,
            iconName: iconName,
            color: color
        )
        loadSavingsGoals()
    }
    
    func deleteGoal(_ goal: SavingsGoal) {
        repository.deleteSavingsGoal(goal)
        loadSavingsGoals()
    }
    
    var activeGoals: [SavingsGoal] {
        savingsGoals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [SavingsGoal] {
        savingsGoals.filter { $0.isCompleted }
    }
    
    func completeGoal(_ goal: SavingsGoal) {
        repository.createTransactionForCompletedGoal(goal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updateAllGoalsProgress()
        }
    }
    
    func extendGoal(_ goal: SavingsGoal, newTargetDate: Date) {
        repository.updateSavingsGoal(
            goal,
            title: goal.title ?? "",
            targetAmount: goal.targetAmount,
            targetDate: newTargetDate,
            iconName: goal.iconName,
            color: goal.color
        )
        loadSavingsGoals()
    }
    
    func rescheduleAllNotifications() {
        let goals = repository.fetchSavingsGoals()
        for goal in goals {
            NotificationManager.shared.scheduleSavingsGoalExpirationNotifications(for: goal)
        }
    }
}

