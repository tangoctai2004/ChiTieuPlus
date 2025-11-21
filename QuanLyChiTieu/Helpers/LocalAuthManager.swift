import Foundation
import LocalAuthentication
import Combine

class LocalAuthManager: ObservableObject {
    
    // MARK: - Trạng thái
    
    @Published var isUnlocked: Bool = false
    @Published var isAppLockEnabled: Bool = false
    @Published var isFaceIDEnabled: Bool = false
    @Published var needsPasscodeEntry: Bool = false

    private let faceIDEnabledKey = "isFaceIDEnabled"
    
    
    init() {
        if KeychainService.shared.getPasscode() != nil {
            self.isAppLockEnabled = true
            self.isUnlocked = false
        } else {
            self.isAppLockEnabled = false
            self.isUnlocked = true
        }
        
        self.isFaceIDEnabled = UserDefaults.standard.bool(forKey: faceIDEnabledKey)
    }
    
    // MARK: - Xác thực
    
    func authenticate() {
        guard isAppLockEnabled else {
            self.isUnlocked = true
            return
        }
        
        if needsPasscodeEntry {
            return
        }

        if isFaceIDEnabled {
            let context = LAContext()
            var error: NSError?
            let reason = "Xác thực để mở khóa Sổ Thu Chi."
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
                    DispatchQueue.main.async {
                        if success {
                            self?.isUnlocked = true
                            self?.needsPasscodeEntry = false
                        } else {
                            self?.needsPasscodeEntry = true
                        }
                    }
                }
            } else {
                self.needsPasscodeEntry = true
            }
        } else {
            self.needsPasscodeEntry = true
        }
    }
    
    func passcodeWasSet() {
        self.isAppLockEnabled = true
        self.isUnlocked = true
        
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            self.isFaceIDEnabled = true
            UserDefaults.standard.set(true, forKey: faceIDEnabledKey)
        }
    }

    func unlockApp() {
        self.isUnlocked = true
        self.needsPasscodeEntry = false
        self.attempts = 0 // Reset bộ đếm
    }
    
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
    
    func toggleFaceIDSetting() {
        let newSetting = !isFaceIDEnabled
        self.isFaceIDEnabled = newSetting
        UserDefaults.standard.set(newSetting, forKey: faceIDEnabledKey)
    }

    func lockApp() {
        if isAppLockEnabled {
            self.isUnlocked = false
            self.needsPasscodeEntry = false
        }
    }
    // MARK: - Xử lý nhập sai
    
    @Published var attempts: Int = 0
    @Published var isLockedOut: Bool = false
    
    func handleWrongPasscode() {
        self.attempts += 1
    }
}
