//
//  TutorialOverlayView.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/11/25.
//

import SwiftUI

struct TutorialOverlayView: View {
    @ObservedObject var tutorialManager: TutorialManager
    @State private var chatOpacity: Double = 0
    
    var body: some View {
        if let step = tutorialManager.currentStep {
            VStack {
                if step.position == .top || step.position == .center {
                    Spacer()
                }
                
                // Chat Bubble đơn giản
                VStack(spacing: 12) {
                    HStack(alignment: .bottom, spacing: 12) {
                        // Character Avatar
                        Circle()
                            .fill(AppColors.brandGradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        // Chat Bubble
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey(step.messageKey))
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .multilineTextAlignment(.leading)
                            
                            Button(action: {
                                tutorialManager.nextStep()
                            }) {
                                HStack {
                                    Text("tutorial_next")
                                        .font(.system(.subheadline, design: .rounded).bold())
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.primaryButton)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.cardBackground)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .frame(maxWidth: 300)
                    }
                    
                    // Skip button
                    Button(action: {
                        tutorialManager.skipTutorial()
                    }) {
                        Text("tutorial_skip")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .opacity(chatOpacity)
                .padding(.horizontal, 20)
                
                if step.position == .bottom {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    chatOpacity = 1.0
                }
            }
            .onChange(of: tutorialManager.currentStepIndex) { _ in
                chatOpacity = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        chatOpacity = 1.0
                    }
                }
            }
        }
    }
}

