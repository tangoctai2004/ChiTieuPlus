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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
//    Chuyen chuoi da dinh dang ve so -> save coredata
    static func currencyToDouble(_ input:String) -> Double{
        Double(input.filter { "0123456789".contains($0)}) ?? 0
    }
    
    static let transactionTypes: [String] = ["income", "expense"]
    
    static func displayType(_ type: String) -> String {
        switch type{
        case "income": return "Thu nhập"
        case "expense": return "Chi tiêu"
        default: return type
        }
    }
    
    static func formattedCurrency(_ amount: Double) -> String{
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        
        let numberString = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(numberString) vnđ"
    }
}
 
