import SwiftUI

struct IntroView: View {
    @Binding var isShowingIntro: Bool
    
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    // 1. SAO CHÉP BIẾN GRADIENT TỪ HOMESCREEN VÀO ĐÂY
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                AppColors.expenseColor,
                Color(light: Color(red: 0.6, green: 0.2, blue: 0.8),
                      dark: Color(red: 0.7, green: 0.3, blue: 0.9))
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // 2. TẠO VSTACK ĐỂ CHỨA CẢ LOGO VÀ TEXT
            VStack(spacing: 20) { // Thêm khoảng cách giữa logo và chữ
                
                // Logo của bạn (đã ở trong VStack)
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                // 3. SAO CHÉP KHỐI TEXT TỪ HOMESCREEN
                (Text("common_expense")
                    // Đặt màu .white cho rõ ràng trên nền đen
                    .foregroundColor(.white)
                +
                Text("+")
                    .foregroundStyle(gradient)
                )
                .font(.custom("Bungee-Regular", size: 40))
                
            }
            // 4. ÁP DỤNG HIỆU ỨNG CHO CẢ VSTACK
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            // (Phần onAppear giữ nguyên như cũ)
            
            withAnimation(.easeInOut(duration: 1.0)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 0.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isShowingIntro = false
            }
        }
    }
}
