import SwiftUI
import Combine

struct EnterPasscodeView: View {
    @State private var pin: String = ""
    @State private var pinLength: Int = 4 // Sẽ được cập nhật
    @State private var savedPin: String? = nil
    @State private var errorMessage: String = "Nhập mã PIN để mở khóa"
    @State private var attempts: Int = 0
    
    // Biến này sẽ được truyền từ LocalAuthManager
    @ObservedObject var authManager: LocalAuthManager
    
    // Dùng để tạo hiệu ứng rung
    @State private var shake: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Nhập mã PIN")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            Text(errorMessage)
                .foregroundColor(attempts > 0 ? .red : .primary)
                .font(.headline)
            
            // Hiển thị các dấu chấm (• • • •)
            PasscodeIndicator(pin: $pin, pinLength: pinLength)
                .modifier(ShakeEffect(shakes: shake * 2)) // Hiệu ứng rung
            
            Spacer()
            
            HStack {
                // Nút "Dùng Face ID" (nếu có)
                if authManager.isFaceIDEnabled {
                    Button("Thử lại Face ID") {
                        authManager.authenticate()
                    }
                    .padding()
                }
                
                Spacer()
                
                // Nút "Quên mã PIN"
                Button("Quên mã PIN?") {
                    // (Bạn có thể thêm logic reset ở đây sau)
                }
                .padding()
            }
            
            // Bàn phím số
            NumberPadView(pin: $pin)
        }
        .padding(.bottom)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            // Khi view xuất hiện, lấy mã PIN đã lưu
            loadSavedPin()
        }
        .onChange(of: pin) { newValue in
            // Khi gõ đủ
            if newValue.count == pinLength {
                checkPin()
            }
        }
    }
    
    private func loadSavedPin() {
        self.savedPin = KeychainService.shared.getPasscode()
        if let savedPin = savedPin {
            // Tự động cập nhật 4/6 số
            self.pinLength = savedPin.count
        } else {
            // Trường hợp lỗi: không có PIN nào được lưu
            // (Lẽ ra không bao giờ xảy ra)
            self.errorMessage = "Lỗi: Không tìm thấy mã PIN"
        }
    }
    
    private func checkPin() {
        if self.pin == self.savedPin {
            // ĐÚNG PIN! -> Mở khóa
            authManager.unlockApp()
        } else {
            // SAI PIN!
            self.attempts += 1
            self.errorMessage = "Mã PIN sai. Thử lại."
            
            // Rung
            withAnimation(.default) {
                self.shake += 1
            }
            
            // Reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.pin = ""
            }
        }
    }
    
    // --- CÁC VIEW PHỤ ---
    
    struct PasscodeIndicator: View {
        @Binding var pin: String
        var pinLength: Int
        
        var body: some View {
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .stroke(Color.primary, lineWidth: 1)
                        .background(
                            Circle()
                                .fill(index < pin.count ? Color.primary : Color.clear)
                        )
                        .frame(width: 15, height: 15)
                }
            }
            .padding()
        }
    }

    struct NumberPadView: View {
        @Binding var pin: String
        private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
        private let buttons = [
            "1", "2", "3",
            "4", "5", "6",
            "7", "8", "9",
            "", "0", "delete.left"
        ]
        
        var body: some View {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(buttons, id: \.self) { button in
                    if button.isEmpty {
                        Rectangle().fill(Color.clear)
                    } else if button == "delete.left" {
                        Button(action: {
                            if !pin.isEmpty {
                                pin.removeLast()
                            }
                        }) {
                            Image(systemName: "delete.left")
                                .font(.title)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        }
                    } else {
                        Button(action: {
                            pin.append(button)
                        }) {
                            Text(button)
                                .font(.title)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // Hiệu ứng rung
    struct ShakeEffect: GeometryEffect {
        var shakes: Int
        
        var animatableData: CGFloat {
            get { CGFloat(shakes) }
            set { shakes = Int(newValue) }
        }
        
        func effectValue(size: CGSize) -> ProjectionTransform {
            let translationX = sin(animatableData * .pi * 2) * 10
            return ProjectionTransform(CGAffineTransform(translationX: translationX, y: 0))
        }
    }
}