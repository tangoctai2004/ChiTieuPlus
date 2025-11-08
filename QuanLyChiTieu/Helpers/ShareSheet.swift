//
//  ShareSheet.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/10/25.
//


//
//  ShareSheet.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/10/25.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Không cần cập nhật
    }
}