import SwiftUI

// --- SỬA ĐỔI 1: Thêm struct helper này ---
// Struct này giúp .sheet(item:) hoạt động với URL
struct ShareableURL: Identifiable {
    let id = UUID() // Thêm ID
    let url: URL    // Bọc URL
}
// --- KẾT THÚC SỬA ĐỔI 1 ---


struct BackupRestoreScreen: View {
    
    // --- SỬA ĐỔI 2: Thay đổi @State ---
    // @State private var isShowingShareSheet = false // <-- Đã xóa
    // @State private var csvFileURL: URL? // <-- Đã xóa
    @State private var shareableURL: ShareableURL? // <-- Thay bằng biến này
    // --- KẾT THÚC SỬA ĐỔI 2 ---
    
    // 2. Hàm xử lý logic xuất file
    private func exportData() {
        do {
            if let url = try CSVService.shared.saveTransactionsToCSV() {
                // --- SỬA ĐỔI 3: Gán cho biến mới ---
                // Gán cho item, .sheet(item:) sẽ tự động kích hoạt
                self.shareableURL = ShareableURL(url: url)
                // self.isShowingShareSheet = true // <-- Đã xóa
                // --- KẾT THÚC SỬA ĐỔI 3 ---
            } else {
                print("Không có dữ liệu để xuất")
            }
        } catch {
            print("Lỗi khi lưu file CSV: \(error.localizedDescription)")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // --- Card Xuất Dữ Liệu ---
                VStack(alignment: .leading, spacing: 12) {
                    Text("backup_export_title")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("backup_export_desc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: exportData) { // Logic không đổi
                        Text("backup_export_button")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                
                // --- Card Khôi Phục Dữ Liệu (Không đổi) ---
                VStack(alignment: .leading, spacing: 12) {
                    Text("backup_import_title")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("backup_import_desc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("backup_import_process_title")
                        .font(.headline)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("backup_import_step1")
                        Text("backup_import_step2")
                        Text("backup_import_step3")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("settings_row_export_data")
        .navigationBarTitleDisplayMode(.inline)
        
        // --- SỬA ĐỔI 4: Thay đổi modifier .sheet ---
        .sheet(item: $shareableURL, onDismiss: {
            // Logic onDismiss không đổi
            if let item = shareableURL {
                try? FileManager.default.removeItem(at: item.url)
                shareableURL = nil // Gán lại là nil
            }
        }) { item in
            // "item" ở đây chính là ShareableURL đã được gán
            // Không cần "if let" hay text "Đang tải" nữa
            ShareSheet(activityItems: [item.url])
        }
        // --- KẾT THÚC SỬA ĐỔI 4 ---
    }
}

// ... (Preview giữ nguyên) ...
