import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.YourAppName.passcode"
    private let accountName = "userPasscode"
    
    func savePasscode(_ passcode: String) -> Bool {
        guard let passcodeData = passcode.data(using: .utf8) else {
            print("Keychain: Không thể chuyển PIN sang Data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: passcodeData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
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
    
    func getPasscode() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data,
               let passcode = String(data: retrievedData, encoding: .utf8) {
                print("Keychain: Đã ĐỌC mã PIN.")
                return passcode
            }
        }
        
        print("Keychain: Không tìm thấy mã PIN (lỗi: \(status)).")
        return nil
    }
    
    func deletePasscode() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
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
