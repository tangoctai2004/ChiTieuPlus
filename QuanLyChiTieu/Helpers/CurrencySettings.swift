//
//  CurrencySettings.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import SwiftUI

enum Currency: String, CaseIterable, Identifiable {
    case vnd = "VND"
    case usd = "USD"
    
    var id: Self { self }
    
    var symbol: String {
        switch self {
        case .vnd:
            return "vnđ"
        case .usd:
            return "$"
        }
    }
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .vnd:
            return "currency_vnd"
        case .usd:
            return "currency_usd"
        }
    }
}

class CurrencySettings: ObservableObject {
    static let shared = CurrencySettings()
    
    @AppStorage("selectedCurrency") var selectedCurrency: String = Currency.vnd.rawValue
    
    var currentCurrency: Currency {
        Currency(rawValue: selectedCurrency) ?? .vnd
    }
    
    // Tỷ giá: 1 USD = 26,377 VND
    static let usdToVndRate: Double = 26377.0
    
    private init() {}
    
    // Chuyển đổi từ VND (lưu trong database) sang currency hiện tại
    func convertFromVnd(_ vndAmount: Double) -> Double {
        // Validate input
        guard vndAmount.isFinite && !vndAmount.isNaN else {
            return 0
        }
        
        switch currentCurrency {
        case .vnd:
            return vndAmount
        case .usd:
            let result = vndAmount / CurrencySettings.usdToVndRate
            return result.isFinite && !result.isNaN ? result : 0
        }
    }
    
    // Chuyển đổi từ currency hiện tại về VND (để lưu vào database)
    func convertToVnd(_ amount: Double) -> Double {
        // Validate input
        guard amount.isFinite && !amount.isNaN else {
            return 0
        }
        
        switch currentCurrency {
        case .vnd:
            return amount
        case .usd:
            let result = amount * CurrencySettings.usdToVndRate
            return result.isFinite && !result.isNaN ? result : 0
        }
    }
}

