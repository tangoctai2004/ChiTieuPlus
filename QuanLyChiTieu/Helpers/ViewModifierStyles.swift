// ViewModifiersStyles.swift
import SwiftUI

// MARK: - Button Styles

//Button style chính (xanh/xám)
struct PrimaryActionButtonStyle: ButtonStyle {
    var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEnabled ? Color.green : Color.gray)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

//Button style xoá (màu đỏ)
struct DestructiveActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - View Modifiers

//Modifier cho thanh chứa nút bấm ở dưới cùng
struct BottomActionBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                Color(.systemGroupedBackground)
                    .shadow(
                        color: Color.primary.opacity(0.1),
                        radius: 2,
                        x: 0,
                        y: -2
                    )
            )
            .padding(.bottom, 35)
    }
}

//Modifier cho nền của các section trong form
struct FormSectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
}

//Modifier cho nền và shadow của các hàng trong danh sách
struct ListRowBackgroundModifier: ViewModifier {
     func body(content: Content) -> some View {
         content
             .padding(15)
             .background(
                 RoundedRectangle(cornerRadius: 20, style: .continuous)
                     .fill(Color(.systemBackground))
                     .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
             )
     }
}

//Modifier để thêm cử chỉ vuốt quay lại
struct SwipeBackGestureModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    
    var backGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                if value.startLocation.x < 50 && value.translation.width > 100 {
                    withAnimation(.easeInOut) {
                        dismiss()
                    }
                }
            }
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(backGesture)
    }
}

// MARK: - Extension tiện lợi
extension View {
//    Áp dụng style cho thanh nút bấm dưới cùng
    func bottomActionBar() -> some View {
        modifier(BottomActionBarModifier())
    }
    
//    Áp dụng style cho section trong form
    func formSectionStyle() -> some View {
        modifier(FormSectionModifier())
    }
    
//    Áp dụng style cho hàng trong danh sách
    func listRowBackgroundStyle() -> some View {
         modifier(ListRowBackgroundModifier())
     }
     
//    Thêm cử chỉ vuốt từ cạnh trái để dismiss
    func addSwipeBackGesture() -> some View {
        self.modifier(SwipeBackGestureModifier())
    }
}
