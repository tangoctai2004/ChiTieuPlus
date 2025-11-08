import Foundation
import LocalAuthentication
import Combine

class LocalAuthManager: ObservableObject {
    
    // --- TRẠNG THÁI CHUNG ---
    /// Trạng thái cuối cùng. `false` = App đang khóa
    @Published var isUnlocked: Bool = false
    
    /// Biến kiểm soát chính: App có đang bật khóa (PIN/FaceID) không?
    @Published var isAppLockEnabled: Bool = false
    
    /// BiBến kiểm soát phụ: Người dùng có cho phép dùng Face ID không?
    @Published var isFaceIDEnabled: Bool = false
    
    /// `true` = Face ID thất bại, cần hiện màn hình nhập PIN
    @Published var needsPasscodeEntry: Bool = false

    
    // --- KHÓA LƯU TRỮ ---
    private let faceIDEnabledKey = "isFaceIDEnabled" // Lưu vào UserDefaults
    
    
    init() {
        // 1. Kiểm tra xem có mã PIN nào được lưu trong Keychain không
        if KeychainService.shared.getPasscode() != nil {
            // Nếu có, có nghĩa là app đang được khóa
            self.isAppLockEnabled = true
            self.isUnlocked = false // Khóa app khi khởi động
        } else {
            // Nếu không có mã PIN, app không bị khóa
            self.isAppLockEnabled = false
            self.isUnlocked = true // Mở app
        }
        
        // 2. Kiểm tra xem người dùng có BẬT Face ID không (lưu ở lần trước)
        self.isFaceIDEnabled = UserDefaults.standard.bool(forKey: faceIDEnabledKey)
    }
    
    /// 1. HÀM XÁC THỰC CHÍNH (gọi từ ContentView)
    func authenticate() {
        // Nếu app không bật khóa, mở ngay
        guard isAppLockEnabled else {
            self.isUnlocked = true
            return
        }
        
        // Nếu app có bật khóa, nhưng đang ở trạng thái cần nhập PIN
        // (ví dụ: Face ID fail lần 1), thì không chạy Face ID nữa
        if needsPasscodeEntry {
            return
        }

        // Nếu người dùng có BẬT Face ID -> Thử Face ID trước
        if isFaceIDEnabled {
            let context = LAContext()
            var error: NSError?
            let reason = "Xác thực để mở khóa Sổ Thu Chi."
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
                    DispatchQueue.main.async {
                        if success {
                            // Thành công -> Mở khóa
                            self?.isUnlocked = true
                            self?.needsPasscodeEntry = false
                        } else {
                            // Thất bại (hoặc nhấn Hủy) -> Chuyển sang nhập PIN
                            self?.needsPasscodeEntry = true
                        }
                    }
                }
            } else {
                // Thiết bị không có Face ID -> Chuyển sang nhập PIN
                self.needsPasscodeEntry = true
            }
        } else {
            // Người dùng không bật Face ID -> Chuyển thẳng sang nhập PIN
            self.needsPasscodeEntry = true
        }
    }
    
    /// 2. HÀM GỌI TỪ "SetPasscodeView" (khi tạo PIN thành công)
    func passcodeWasSet() {
        self.isAppLockEnabled = true
        self.isUnlocked = true // Mở khóa (vì vừa tạo xong)
        
        // Tự động bật Face ID (nếu có thể)
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            self.isFaceIDEnabled = true
            UserDefaults.standard.set(true, forKey: faceIDEnabledKey)
        }
    }

    /// 3. HÀM GỌI TỪ "EnterPasscodeView" (khi nhập PIN đúng)
    func unlockApp() {
        self.isUnlocked = true
        self.needsPasscodeEntry = false
        self.attempts = 0 // Reset bộ đếm
    }
    
    /// 4. HÀM GỌI TỪ "SettingScreen" (khi gạt Tắt Khóa)
    func disableAppLock() {
        if KeychainService.shared.deletePasscode() {
            self.isAppLockEnabled = false
            self.isFaceIDEnabled = false
            UserDefaults.standard.set(false, forKey: faceIDEnabledKey)
            self.isUnlocked = true // Mở khóa vĩnh viễn
        } else {
            print("Lỗi: Không thể xóa mã PIN khỏi Keychain.")
        }
    }
    
    /// 5. HÀM GỌI TỪ "SettingScreen" (khi gạt Bật/Tắt Face ID)
    func toggleFaceIDSetting() {
        let newSetting = !isFaceIDEnabled
        self.isFaceIDEnabled = newSetting
        UserDefaults.standard.set(newSetting, forKey: faceIDEnabledKey)
    }

    /// 6. HÀM GỌI TỪ "ContentView" (khi app vào background)
    func lockApp() {
        if isAppLockEnabled {
            self.isUnlocked = false
            // Khi khóa app, reset lại để lần sau thử Face ID trước
            self.needsPasscodeEntry = false
        }
    }
    
    // --- LOGIC XỬ LÝ NHẬP SAI ---
    
    @Published var attempts: Int = 0
    @Published var isLockedOut: Bool = false // (Tạm thời chưa dùng, sẽ nâng cấp sau)
    
    /// 7. HÀM GỌI TỪ "EnterPasscodeView" (khi nhập PIN sai)
    func handleWrongPasscode() {
        self.attempts += 1
        // (Bạn có thể thêm logic khóa tạm thời ở đây)
    }
}
