//
//  AppUtils.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//
import Foundation
import UIKit

struct AppUtils{

//    Dinh dang so tien nhap vao
    static func formatCurrencyInput(_ input:String) -> String{
        let raw = input.filter { "0123456789".contains($0) }
        let number = Double(raw) ?? 0
        
        // Validate number trước khi format
        guard number.isFinite && !number.isNaN && number >= 0 else {
            return ""
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
//    Chuyen chuoi da dinh dang ve so -> save coredata
    static func currencyToDouble(_ input:String) -> Double{
        let raw = input.filter { "0123456789".contains($0) }
        let number = Double(raw) ?? 0
        
        // Validate và đảm bảo giá trị hợp lệ
        if number.isFinite && !number.isNaN && number >= 0 {
            return number
        }
        return 0
    }
    
    static let transactionTypes: [String] = ["income", "expense"]
    
    static func displayType(_ type: String) -> String {
        switch type{
        case "income": return "Thu nhập"
        case "expense": return "Chi tiêu"
        default: return type
        }
    }
    
    static func formattedCurrency(_ amount: Double, currencySettings: CurrencySettings? = nil) -> String{
        // Validate amount trước khi format
        guard amount.isFinite && !amount.isNaN && amount >= 0 else {
            return "0 \(CurrencySettings.shared.currentCurrency.symbol)"
        }
        
        let currencySettings = currencySettings ?? CurrencySettings.shared
        let convertedAmount = currencySettings.convertFromVnd(amount)
        
        // Validate convertedAmount
        guard convertedAmount.isFinite && !convertedAmount.isNaN else {
            return "0 \(currencySettings.currentCurrency.symbol)"
        }
        
        let currency = currencySettings.currentCurrency
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        // Với USD, hiển thị 2 chữ số thập phân. Với VND, không có số thập phân
        if currency == .usd {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else {
            formatter.maximumFractionDigits = 0
        }
        
        let numberString = formatter.string(from: NSNumber(value: convertedAmount)) ?? "0"
        return "\(numberString) \(currency.symbol)"
    }
}
 
