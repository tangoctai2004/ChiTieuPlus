//
//  ChartDataPoint.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 24/10/25.
//

import Foundation

struct ChartDataPoint: Identifiable, Hashable {
    let id = UUID()
    let month: Int
    let monthLabel: String
    var totalAmount: Double
}
