import Foundation
import Security

// Lớp này sẽ xử lý việc lưu và đọc mã PIN
// một cách an toàn từ Keychain
class KeychainService {
    
    // Dùng singleton để dễ truy cập
    static let shared = KeychainService()
    
    // Tên "dịch vụ" và "tài khoản" để nhận diện
    // mục của chúng ta trong Keychain
    private let serviceName = "com.YourAppName.passcode" // <-- Bạn có thể đổi YourAppName
    private let accountName = "userPasscode"
    
    /// Lưu mã PIN vào Keychain
    func savePasscode(_ passcode: String) -> Bool {
        // Chuyển chuỗi String thành Data
        guard let passcodeData = passcode.data(using: .utf8) else {
            print("Keychain: Không thể chuyển PIN sang Data")
            return false
        }
        
        // 1. Tạo "query" (câu lệnh) để tìm
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        // 2. Tạo "attributes" (thuộc tính) để cập nhật
        let attributes: [String: Any] = [
            kSecValueData as String: passcodeData
        ]
        
        // 3. Thử CẬP NHẬT (Update) nếu đã có
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // 4. Nếu cập nhật thất bại (vì chưa có)
        if status == errSecItemNotFound {
            // ... thì THÊM MỚI (Add)
            var addQuery = query
            addQuery[kSecValueData as String] = passcodeData
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            if addStatus == errSecSuccess {
                print("Keychain: Đã LƯU mã PIN mới.")
                return true
            } else {
                print("Keychain: Lỗi khi THÊM MỚI mã PIN. Lỗi: \(addStatus)")
                return false
            }
        } else if status != errSecSuccess {
            print("Keychain: Lỗi khi CẬP NHẬT mã PIN. Lỗi: \(status)")
            return false
        }
        
        print("Keychain: Đã CẬP NHẬT mã PIN.")
        return true
    }
    
    /// Đọc mã PIN từ Keychain
    func getPasscode() -> String? {
        // 1. Tạo query để tìm
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: kCFBooleanTrue!, // Yêu cầu trả về dữ liệu
            kSecMatchLimit as String: kSecMatchLimitOne // Chỉ cần 1 kết quả
        ]
        
        var dataTypeRef: AnyObject?
        
        // 2. Thực thi lệnh tìm
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            // 3. Nếu thành công, chuyển Data về String
            if let retrievedData = dataTypeRef as? Data,
               let passcode = String(data: retrievedData, encoding: .utf8) {
                print("Keychain: Đã ĐỌC mã PIN.")
                return passcode
            }
        }
        
        // Không tìm thấy hoặc lỗi
        print("Keychain: Không tìm thấy mã PIN (lỗi: \(status)).")
        return nil
    }
    
    /// Xóa mã PIN khỏi Keychain
    func deletePasscode() -> Bool {
        // 1. Tạo query để tìm
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        // 2. Thực thi lệnh xóa
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("Keychain: Đã XÓA mã PIN.")
            return true
        } else if status == errSecItemNotFound {
            print("Keychain: Không có gì để xóa.")
            return true // Vẫn coi là thành công
        }
        
        print("Keychain: Lỗi khi XÓA mã PIN. Lỗi: \(status)")
        return false
    }
}
