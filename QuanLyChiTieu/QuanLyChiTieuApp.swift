//
//  QuanLyChiTieuApp.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 27/8/25.
//

import SwiftUI

@main
struct QuanLyChiTieuApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
