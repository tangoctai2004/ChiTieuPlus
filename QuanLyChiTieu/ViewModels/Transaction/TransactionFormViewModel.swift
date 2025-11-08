import Foundation
import CoreData
import Combine

class TransactionFormViewModel: ObservableObject {
    @Published var transactionTitle: String = ""
    @Published var note: String = ""
    @Published var rawAmount: String = ""
    @Published var formattedAmount: String = ""
    @Published var date: Date = Date()
    @Published var type: String = "expense" {
        didSet {
            if oldValue != type {
                selectedCategory = nil
                selectedCategoryID = nil
            }
        }
    }
    @Published var selectedCategoryID: NSManagedObjectID?
    @Published var selectedCategory: Category?
    
    @Published private var allCategories: [Category] = []
    private var speechService: SpeechRecognitionService?
    private var cancellables = Set<AnyCancellable>()
    
    private var transactionToEdit: Transaction?
    private let repository: DataRepository
    
    var isEditing: Bool {
        transactionToEdit != nil
    }
    
    var canSave: Bool {
        AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategoryID != nil
    }
    
    init(repository: DataRepository = .shared, transaction: Transaction? = nil) {
        self.repository = repository
        self.transactionToEdit = transaction
        
        reinitializeFromTransaction()
        
        repository.categoriesPublisher
            .sink { [weak self] categories in
                self?.allCategories = categories
            }
            .store(in: &cancellables)
    }
    
    func loadCategoryData() {
        repository.fetchCategories()
    }
    
    func reinitializeFromTransaction() {
        if let transaction = transactionToEdit {
            self.transactionTitle = transaction.title ?? ""
            self.note = transaction.note ?? ""
            self.date = transaction.date ?? Date()
            self.type = transaction.type ?? "expense"
            self.selectedCategory = transaction.category
            self.selectedCategoryID = transaction.category?.objectID
            let initialRawAmount = String(Int(transaction.amount))
            self.rawAmount = initialRawAmount
            self.formattedAmount = AppUtils.formatCurrencyInput(initialRawAmount)
        }
    }
    
    func save() {
        let formData = TransactionFormData(
            transactionTitle: transactionTitle,
            note: note,
            rawAmount: rawAmount,
            date: date,
            type: type,
            selectedCategoryID: selectedCategoryID
        )
        
        if let transaction = transactionToEdit {
            repository.updateTransaction(transaction, formData: formData)
        } else {
            repository.addTransaction(formData: formData)
        }
        
        // --- THÊM DÒNG NÀY ---
        // Báo cho NotificationManager biết là đã lưu,
        // để nó hủy lịch hôm nay và đặt lịch ngày mai.
        NotificationManager.shared.handleSuccessfulSave()
        // --- KẾT THÚC THÊM MỚI ---
    }
    
    func delete() {
        if let transaction = transactionToEdit {
            repository.deleteTransaction(transaction)
        }
    }

    func reset() {
        transactionTitle = ""
        note = ""
        rawAmount = ""
        formattedAmount = ""
        date = Date()
        selectedCategory = nil
        selectedCategoryID = nil
    }
    
    // MARK: - LOGIC NHẬN DIỆN GIỌNG NÓI
    
    func setupSpeechService(_ service: SpeechRecognitionService) {
        self.speechService = service
        self.speechService?.requestAuthorization()
        
        self.speechService?.$isRecording
            .receive(on: RunLoop.main)
            .dropFirst()
            .filter { $0 == false }
            .sink { [weak self] _ in
                guard let text = self?.speechService?.transcribedText, !text.isEmpty else {
                    print("Nhận diện giọng nói: không có văn bản.")
                    return
                }
                print("Nhận diện giọng nói: Đã nhận text - \(text)")
                self?.parseSpeechResult(text)
            }
            .store(in: &cancellables)
    }

    func toggleRecording() {
        if !(speechService?.isRecording ?? false) {
            speechService?.transcribedText = ""
            reset()
        }
        speechService?.toggleRecording()
    }
    
    private func parseSpeechResult(_ text: String) {
        var processedText = text.lowercased()
        
        // 1. Kiểm tra danh mục
        var categoriesToSearch = self.allCategories
        
        // 2. Nếu rỗng, nạp đồng bộ
        if categoriesToSearch.isEmpty {
            print("Phát hiện race condition, đang nạp danh mục đồng bộ...")
            categoriesToSearch = repository.fetchAllCategoriesSync() // Gọi hàm mới
            
            DispatchQueue.main.async {
                self.allCategories = categoriesToSearch
            }
        }
        
        DispatchQueue.main.async {
            let (date, textAfterDate) = self.extractDate(from: processedText)
            self.date = date
            processedText = textAfterDate
            
            let (amount, textAfterAmount) = self.extractAmount(from: processedText)
            if amount > 0 {
                let rawAmountString = String(Int(amount))
                self.rawAmount = rawAmountString
                self.formattedAmount = AppUtils.formatCurrencyInput(rawAmountString)
            }
            processedText = textAfterAmount.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 3. Truyền danh sách đã nạp
            let (category, title) = self.findCategoryAndTitle(for: processedText, in: categoriesToSearch)
            
            if let category = category {
                self.selectedCategory = category
                self.selectedCategoryID = category.objectID
                
                if let categoryType = category.type {
                    self.type = categoryType
                }
            }
            
            self.transactionTitle = title.capitalized
            self.note = ""
        }
    }
    
    private func extractDate(from text: String) -> (Date, String) {
        var remainingText = text
        
        if text.contains("hôm qua") {
            remainingText = remainingText.replacingOccurrences(of: "hôm qua", with: "")
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                return (yesterday, remainingText)
            }
        }
        
        if text.contains("hôm nay") {
            remainingText = remainingText.replacingOccurrences(of: "hôm nay", with: "")
            return (Date(), remainingText)
        }
        
        return (Date(), text)
    }
    
    private func extractAmount(from text: String) -> (Double, String) {
        // Pattern mới: tìm cả dấu chấm [\d\.] và thêm "triệu", "tr"
        let pattern = #"([\d\.]+)\s*(k|ca|nghìn|ngàn|trăm|triệu|tr)?"#
        var amount: Double = 0
        var processedText = text

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            if let match = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: processedText.utf16.count)).first {
                
                if let numberRange = Range(match.range(at: 1), in: processedText) {
                    var numberString = String(processedText[numberRange])
                    
                    numberString = numberString.replacingOccurrences(of: ".", with: "")
                    
                    if var number = Double(numberString) {
                        
                        var multiplier: Double = 1.0
                        
                        if let unitRange = Range(match.range(at: 2), in: processedText) {
                            let unit = String(processedText[unitRange]).lowercased()
                            
                            if unit == "k" || unit == "nghìn" || unit == "ngàn" || unit == "ca" {
                                multiplier = 1000
                            } else if unit == "trăm" {
                                multiplier = 100
                            } else if unit == "triệu" || unit == "tr" {
                                multiplier = 1000000
                            }
                            
                        } else {
                            if number < 1000 {
                                multiplier = 1000
                            } else {
                                multiplier = 1
                            }
                        }
                        
                        amount = number * multiplier
                        
                        if let fullMatchRange = Range(match.range(at: 0), in: processedText) {
                            processedText = processedText.replacingOccurrences(of: processedText[fullMatchRange], with: "")
                        }
                    }
                }
            }
        } catch {
            print("Regex error: \(error.localizedDescription)")
        }
        
        return (amount, processedText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func findCategoryAndTitle(for text: String, in categories: [Category]) -> (Category?, String) {
        
        // --- BẢN ĐỒ TỪ KHOÁ (Trỏ về KEY) ---
        let keywordMap: [String: String] = [
            // MARK: - DANH MỤC CHI TIÊU (expense)
            "ăn uống": "default_category_food",
            "ăn sáng": "default_category_food",
            "ăn trưa": "default_category_food",
            "ăn tối": "default_category_food",
            "cà phê": "default_category_food",
            "trà sữa": "default_category_food",
            "nhà hàng": "default_category_food",
            "đi chợ": "default_category_food",
            "quần áo": "default_category_clothing",
            "quần": "default_category_clothing",
            "áo": "default_category_clothing",
            "váy": "default_category_clothing",
            "chi tiêu hàng ngày": "default_category_daily_spending",
            "mua sắm": "default_category_daily_spending",
            "siêu thị": "default_category_daily_spending",
            "mỹ phẩm": "default_category_cosmetics",
            "son": "default_category_cosmetics",
            "đồ makeup": "default_category_cosmetics",
            "phí tiệc tùng": "default_category_party",
            "tiệc tùng": "default_category_party",
            "đi nhậu": "default_category_party",
            "sinh nhật": "default_category_party",
            "y tế": "default_category_medical",
            "thuốc": "default_category_medical",
            "tiền thuốc": "default_category_medical",
            "khám bệnh": "default_category_medical",
            "giáo dục": "default_category_education",
            "học phí": "default_category_education",
            "tiền học": "default_category_education",
            "sách": "default_category_education",
            "tiền điện": "default_category_electricity",
            "hóa đơn điện": "default_category_electricity",
            "đi lại": "default_category_transport",
            "xăng": "default_category_transport",
            "tiền xăng": "default_category_transport",
            "grab": "default_category_transport",
            "taxi": "default_category_transport",
            "phí liên lạc": "default_category_communication",
            "tiền điện thoại": "default_category_communication",
            "nạp card": "default_category_communication",
            "cước điện thoại": "default_category_communication",
            "tiền nhà": "default_category_housing",
            "tiền trọ": "default_category_housing",
            "tiền thuê nhà": "default_category_housing",
            
            // MARK: - DANH MỤC THU NHẬP (income)
            "tiền lương": "default_category_salary",
            "lương": "default_category_salary",
            "nhận lương": "default_category_salary",
            "tiền phụ cấp": "default_category_allowance",
            "phụ cấp": "default_category_allowance",
            "tiền thưởng": "default_category_bonus",
            "thưởng": "default_category_bonus",
            "tiền boa": "default_category_bonus",
            "tip": "default_category_bonus",
            "thu nhập phụ": "default_category_side_income",
            "nghề tay trái": "default_category_side_income",
            "freelance": "default_category_side_income",
            "đầu tư": "default_category_investment",
            "lãi": "default_category_investment",
            "lợi nhuận": "default_category_investment",
            "thu nhập tạm thời": "default_category_temporary_income",
            "bán đồ": "default_category_temporary_income",
            "tiền bán đồ": "default_category_temporary_income"
        ]
        
        if categories.isEmpty {
            print("Lỗi: findCategoryAndTitle được gọi với danh sách danh mục rỗng.")
            return (nil, text)
        }
        
        let lowercasedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let sortedKeywords = keywordMap.keys.sorted(by: { $0.count > $1.count })

        for keyword in sortedKeywords {
            if lowercasedText.contains(keyword) {
                let categoryKey = keywordMap[keyword]!
                let categoryKeyLowercased = categoryKey.lowercased()
                
                if let category = categories.first(where: {
                    $0.name?
                      .trimmingCharacters(in: .whitespacesAndNewlines)
                      .lowercased() == categoryKeyLowercased
                }) {
                    return (category, text)
                }
            }
        }
        
        return (nil, text)
    }
}
