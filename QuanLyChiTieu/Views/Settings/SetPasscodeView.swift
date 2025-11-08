import SwiftUI
import Combine

struct SetPasscodeView: View {
    enum PasscodeStep {
        case create
        case confirm
    }
    
    @State private var pin: String = ""
    @State private var pinConfirmation: String = ""
    @State private var pinLength: Int = 4 // Mặc định 4 số
    @State private var currentStep: PasscodeStep = .create
    @State private var errorMessage: String? = nil
    
    // Biến này sẽ được truyền từ SettingScreen để đóng View
    @Binding var isPresented: Bool
    
    // Biến này sẽ được truyền từ LocalAuthManager
    @ObservedObject var authManager: LocalAuthManager

    private var prompt: String {
        switch currentStep {
        case .create:
            return "Tạo mã PIN \(pinLength) số của bạn"
        case .confirm:
            return "Xác nhận lại mã PIN"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(prompt)
                .font(.headline)
                .padding(.top, 40)
            
            // Picker chọn 4/6 số
            Picker("Độ dài mã PIN", selection: $pinLength) {
                Text("4 Số").tag(4)
                Text("6 Số").tag(6)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .disabled(currentStep == .confirm) // Không cho đổi khi đang xác nhận
            
            // Hiển thị các dấu chấm (• • • •)
            PasscodeIndicator(pin: $pin, pinLength: pinLength, currentStep: $currentStep)
            
            // Hiển thị lỗi
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            // Bàn phím số
            NumberPadView(pin: $pin)
        }
        .navigationTitle("Thiết lập mã PIN")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pinLength) { _ in
            resetPasscode() // Nếu đổi 4/6 số, reset
        }
        .onChange(of: pin) { newValue in
            // Khi gõ đủ
            if newValue.count == pinLength {
                processPinEntry()
            }
        }
    }
    
    private func processPinEntry() {
        if currentStep == .create {
            // Bước 1: Đã nhập xong mã -> Chuyển sang xác nhận
            self.pinConfirmation = self.pin
            self.pin = "" // Xóa pin để nhập lại
            self.currentStep = .confirm
        } else {
            // Bước 2: Đã nhập xong mã xác nhận
            if self.pin == self.pinConfirmation {
                // KHỚP! -> Lưu và đóng
                savePasscode()
            } else {
                // KHÔNG KHỚP! -> Báo lỗi và làm lại
                self.errorMessage = "Mã PIN không khớp. Vui lòng thử lại."
                resetPasscode()
            }
        }
    }
    
    private func resetPasscode() {
        self.pin = ""
        self.pinConfirmation = ""
        self.currentStep = .create
    }
    
    private func savePasscode() {
        // Gọi KeychainService để lưu
        if KeychainService.shared.savePasscode(self.pin) {
            print("Đã lưu mã PIN mới.")
            // Báo cho AuthManager biết
            authManager.passcodeWasSet()
            // Đóng màn hình
            isPresented = false
        } else {
            self.errorMessage = "Không thể lưu mã PIN. Vui lòng thử lại."
            resetPasscode()
        }
    }
    
    // --- CÁC VIEW PHỤ ---
    
    struct PasscodeIndicator: View {
        @Binding var pin: String
        var pinLength: Int
        @Binding var currentStep: PasscodeStep
        
        var body: some View {
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.primary : Color.gray.opacity(0.3))
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
                        Rectangle().fill(Color.clear) // Ô trống
                    } else if button == "delete.left" {
                        // Nút Xóa
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
                        // Nút Số
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
}