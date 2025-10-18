//
//  CustomTabBar.swift
//  TabBarAnimation
//
//  Created by Thanh Hoang on 17/2/25.
//

import SwiftUI

struct CustomTabBar: View {
    
    //MARK: - Properties
    @Binding var tabSelection: Int
    var animation: Namespace.ID
    
    private var tabWidth: CGFloat {
        return screenWidth/5
    }
    
    @State private var midPoint: CGFloat = 0.0
    
    //MARK: - Content
    var body: some View {
        let midSize: CGFloat = screenWidth * (200/1000)
        
        ZStack() {
            BezierCurvePath(midPoint: midPoint)
                .foregroundStyle(.black)
            
            HStack(spacing: 0.0) {
                ForEach(0..<TabModel.allCases.count, id: \.self) { index in
                    let tab = TabModel.allCases[index]
                    let isCurrentTab = tabSelection == index+1
                    
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                            tabSelection = index + 1
                            midPoint = tabWidth * (-CGFloat(tabSelection-3))
                        }
                        
                    } label: {
                        VStack(spacing: 2.0) {
                            
                            let iconImage = Image(systemName: tab.systemImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)

                            if isCurrentTab {
                                LinearGradient(
                                    colors: [.red, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .mask(
                                    iconImage
                                        .aspectRatio(0.4, contentMode: .fit)
                                )
                                .frame(
                                    width: midSize,
                                    height: midSize)
                                .background {
                                    Circle()
                                        .fill(.white.gradient)
                                        .matchedGeometryEffect(id: "CurveAnimation", in: animation)
                                }
                                .offset(y: -(midSize/2))
                                
                            } else {
                                iconImage
                                    .aspectRatio(0.6, contentMode: .fit)
                                    .frame(
                                        width: 35.0,
                                        height: 35.0)
                                    .foregroundStyle(.gray)
                                
                                Text(tab.rawValue)
                                    .font(.caption)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: !isCurrentTab ? -8.0 : 0.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: midSize)
        .onAppear {
            midPoint = tabWidth * (-CGFloat(1-3))
        }
    }
}

#Preview {
    ContentView()
}
