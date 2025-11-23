//
//  TutorialManager.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/11/25.
//

import Foundation
import SwiftUI

class TutorialManager: ObservableObject {
    static let shared = TutorialManager()
    
    @Published var isTutorialActive: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var currentScreen: TutorialScreen = .home
    @Published var shouldSwitchToInitialScreen: Bool = false
    
    private let hasCompletedTutorialKey = "hasCompletedTutorial"
    
    private init() {}
    
    var hasCompletedTutorial: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedTutorialKey)
    }
    
    func shouldStartTutorial() -> Bool {
        return !hasCompletedTutorial && !isTutorialActive
    }
    
    func startTutorial() {
        isTutorialActive = true
        currentStepIndex = 0
        let firstStep = TutorialStep.allSteps[0]
        currentScreen = firstStep.screen
        // Báo hiệu cần chuyển tab ngay lập tức
        shouldSwitchToInitialScreen = true
    }
    
    func nextStep() {
        if currentStepIndex < TutorialStep.allSteps.count - 1 {
            currentStepIndex += 1
            let nextStep = TutorialStep.allSteps[currentStepIndex]
            currentScreen = nextStep.screen
        } else {
            completeTutorial()
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    private func completeTutorial() {
        isTutorialActive = false
        currentStepIndex = 0
        UserDefaults.standard.set(true, forKey: hasCompletedTutorialKey)
    }
    
    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: hasCompletedTutorialKey)
        // Force reset về bước đầu tiên và báo hiệu cần chuyển tab
        isTutorialActive = true
        currentStepIndex = 0
        let firstStep = TutorialStep.allSteps[0]
        currentScreen = firstStep.screen
        shouldSwitchToInitialScreen = true
    }
    
    var currentStep: TutorialStep? {
        guard currentStepIndex >= 0 && currentStepIndex < TutorialStep.allSteps.count else {
            return nil
        }
        return TutorialStep.allSteps[currentStepIndex]
    }
}

// MARK: - Tutorial Models
enum TutorialScreen {
    case home
    case category
    case addTransaction
    case dashboard
    case settings
}

struct TutorialStep: Identifiable {
    let id: Int
    let screen: TutorialScreen
    let messageKey: String
    let position: ChatPosition
    
    enum ChatPosition: Equatable {
        case top
        case bottom
        case center
    }
    
    static let allSteps: [TutorialStep] = [
        TutorialStep(id: 1, screen: .home, messageKey: "tutorial_step_1", position: .center),
        TutorialStep(id: 2, screen: .home, messageKey: "tutorial_step_2", position: .top),
        TutorialStep(id: 3, screen: .home, messageKey: "tutorial_step_3", position: .top),
        TutorialStep(id: 4, screen: .addTransaction, messageKey: "tutorial_step_4", position: .center),
        TutorialStep(id: 5, screen: .addTransaction, messageKey: "tutorial_step_5", position: .bottom),
        TutorialStep(id: 6, screen: .dashboard, messageKey: "tutorial_step_6", position: .center),
        TutorialStep(id: 7, screen: .settings, messageKey: "tutorial_step_7", position: .center),
        TutorialStep(id: 8, screen: .home, messageKey: "tutorial_step_8", position: .bottom)
    ]
}

