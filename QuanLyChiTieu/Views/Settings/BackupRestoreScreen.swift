import SwiftUI
import UniformTypeIdentifiers

// Struct này giúp .sheet(item:) hoạt động với URL
struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct BackupRestoreScreen: View {
    @State private var shareableURL: ShareableURL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showImportPicker = false
    @State private var showAlertDialog = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    // Hàm xử lý logic xuất file
    private func exportData() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let url = try CSVService.shared.saveTransactionsToCSV() {
                    DispatchQueue.main.async {
                        self.shareableURL = ShareableURL(url: url)
                        self.isExporting = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Lỗi", message: "Không có dữ liệu để xuất")
                        self.isExporting = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Lỗi xuất dữ liệu", message: error.localizedDescription)
                    self.isExporting = false
                }
            }
        }
    }
    
    // Hàm xử lý import
    private func importData(from url: URL) {
        isImporting = true
        CSVService.shared.parseAndImport(url: url) { result in
            isImporting = false
            switch result {
            case .success(let importResult):
                var message = "Đã thêm \(importResult.added) giao dịch"
                if importResult.skipped > 0 {
                    message += "\nĐã bỏ qua \(importResult.skipped) giao dịch (trùng lặp hoặc không hợp lệ)"
                }
                if !importResult.errors.isEmpty {
                    message += "\n\nCó \(importResult.errors.count) lỗi trong quá trình nhập"
                }
                showAlert(title: "Nhập dữ liệu thành công", message: message)
            case .failure(let error):
                showAlert(title: "Lỗi nhập dữ liệu", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlertDialog = true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Export Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primaryButton.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppColors.primaryButton)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("backup_export_title")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.primary)
                            
                            Text("backup_export_desc")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isExporting ? "Đang xuất..." : "backup_export_button")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isExporting ? Color.gray : AppColors.primaryButton)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                }
                .padding(20)
                .background(AppColors.cardBackground)
                .cornerRadius(20)
                .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
                
                // MARK: - Import Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.incomeColor.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppColors.incomeColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("backup_import_title")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.primary)
                            
                            Text("backup_import_desc")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Button(action: { showImportPicker = true }) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isImporting ? "Đang nhập..." : "Chọn file CSV")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isImporting ? Color.gray : AppColors.incomeColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isImporting)
                    
                    // Import Process Guide
                    VStack(alignment: .leading, spacing: 12) {
                        Text("backup_import_process_title")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ImportStepView(number: 1, text: "backup_import_step1")
                            ImportStepView(number: 2, text: "backup_import_step2")
                            ImportStepView(number: 3, text: "backup_import_step3")
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(AppColors.cardBackground)
                .cornerRadius(20)
                .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 4)
            }
            .padding()
        }
        .background(AppColors.groupedBackground.ignoresSafeArea())
        .navigationTitle("settings_row_export_data")
        .navigationBarTitleDisplayMode(.inline)
        
        .sheet(item: $shareableURL, onDismiss: {
            if let item = shareableURL {
                try? FileManager.default.removeItem(at: item.url)
                shareableURL = nil
            }
        }) { item in
            ShareSheet(activityItems: [item.url])
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    url.startAccessingSecurityScopedResource()
                    importData(from: url)
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                showAlert(title: "Lỗi", message: "Không thể chọn file: \(error.localizedDescription)")
            }
        }
        .alert(alertTitle, isPresented: $showAlertDialog) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Import Step View
struct ImportStepView: View {
    let number: Int
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryButton.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryButton)
            }
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
