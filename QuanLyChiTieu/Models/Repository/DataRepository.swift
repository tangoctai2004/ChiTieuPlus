//
//  DataRepository.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 17/10/25.
//

import Foundation
import CoreData
import Combine

struct TransactionFormData {
    var transactionTitle: String
    var note: String
    var rawAmount: String
    var date: Date
    var type: String
    var selectedCategoryID: NSManagedObjectID?
}

class DataRepository {
    
    static let shared = DataRepository()
    private let context: NSManagedObjectContext
    
    let categoriesPublisher = CurrentValueSubject<[Category], Never>([])
    let transactionsPublisher = CurrentValueSubject<[Transaction], Never>([])
    
    private init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }
    
    // MARK: - Category Functions
    
    func fetchCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let categories = try context.fetch(request)
            categoriesPublisher.send(categories)
        } catch {
            print("❌ Lỗi khi fetch categories: \(error)")
            categoriesPublisher.send([])
        }
    }
    
    func addCategory(name: String, type: String, iconName: String) {
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.type = type
        newCategory.iconName = iconName
        newCategory.createAt = Date()
        newCategory.updateAt = Date()
        saveAndRefreshData()
    }
    
    func updateCategory(_ category: Category, name: String, type: String, iconName: String) {
        category.name = name
        category.type = type
        category.iconName = iconName
        category.updateAt = Date()
        saveAndRefreshData()
    }
    
    func deleteCategory(_ category: Category) {
        context.delete(category)
        saveAndRefreshData()
    }
    
    func fetchCategory(by id: UUID?) -> Category? {
        guard let id = id else { return nil }
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Lỗi khi fetch category by ID: \(error)")
            return nil
        }
    }
    
    func fetchAllCategoriesSync() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            // Dùng context của repository
            return try context.fetch(request)
        } catch {
            print("❌ Lỗi khi fetch categories sync: \(error)")
            return []
        }
    }
    
    // MARK: - Transaction Functions
    
    func fetchTransactions() {
        CoreDataStack.shared.container.performBackgroundTask { backgroundContext in
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
            
            do {
                let transactions = try backgroundContext.fetch(request)
                let transactionIDs = transactions.map { $0.objectID }
                let mainContext = self.context
                
                mainContext.perform {
                    let mainThreadTransactions = transactionIDs.compactMap {
                        try? mainContext.existingObject(with: $0) as? Transaction
                    }
                    self.transactionsPublisher.send(mainThreadTransactions)
                }
            } catch {
                print("❌ Lỗi khi fetch transactions trên background: \(error)")
                self.transactionsPublisher.send([])
            }
        }
    }

    func addTransaction(formData: TransactionFormData) {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        let title = formData.transactionTitle
        
        newTransaction.note = formData.note
        let amount = AppUtils.currencyToDouble(formData.rawAmount)
        // Validate amount trước khi gán
        newTransaction.amount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
        newTransaction.date = formData.date
        newTransaction.type = formData.type
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        if let categoryID = formData.selectedCategoryID,
           let categoryInContext = context.object(with: categoryID) as? Category {
            newTransaction.category = categoryInContext
            newTransaction.title = title.isEmpty ? (categoryInContext.name ?? "common_category") : title
        } else {
            newTransaction.title = title.isEmpty ? "common_category" : title
        }
        
        saveAndRefreshData()
    }
    
    func updateTransaction(
        _ transactionToEdit: Transaction,
        formData: TransactionFormData
    ) {
        let title = formData.transactionTitle
        transactionToEdit.note = formData.note
        let amount = AppUtils.currencyToDouble(formData.rawAmount)
        // Validate amount trước khi gán
        transactionToEdit.amount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
        transactionToEdit.date = formData.date
        transactionToEdit.type = formData.type
        transactionToEdit.updateAt = Date()

        if let categoryID = formData.selectedCategoryID,
           let categoryInContext = context.object(with: categoryID) as? Category {
            transactionToEdit.category = categoryInContext
            transactionToEdit.title = title.isEmpty ? (categoryInContext.name ?? "common_category") : title
        } else {
            transactionToEdit.category = nil
            transactionToEdit.title = title.isEmpty ? "common_category" : title
        }

        saveAndRefreshData()
    }

    func deleteTransaction(_ transaction: Transaction) {
        context.delete(transaction)
        saveAndRefreshData()
    }
    
    private func saveAndRefreshData() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            fetchCategories()
            fetchTransactions()
            updateAllSavingsGoalsProgress()
            updateAllBudgetsSpentAmount()
            NotificationManager.shared.checkAllBudgetsAndNotify()
            NotificationCenter.default.post(name: NSNotification.Name("TransactionDidChange"), object: nil)
        } catch {
            print("❌ Lỗi khi lưu context: \(error)")
        }
    }
    
    private func updateAllSavingsGoalsProgress() {
        let goals = fetchSavingsGoals()
        for goal in goals {
            if let startDate = goal.startDate {
                let currentSavings = calculateTotalSavings(from: startDate)
                updateSavingsGoalProgress(goal, amount: currentSavings)
            }
        }
    }
    // MARK: - Reset Data
    
    func resetAllData() {
        print("Bắt đầu quá trình reset (chỉ xoá Transactions)...")
        
        let transactionDeleteRequest = NSBatchDeleteRequest(fetchRequest: Transaction.fetchRequest())
        transactionDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            let transactionResult = try context.execute(transactionDeleteRequest) as? NSBatchDeleteResult
            let transactionObjectIDs = transactionResult?.result as? [NSManagedObjectID] ?? []
            
            if !transactionObjectIDs.isEmpty {
                let changes = [NSDeletedObjectsKey: transactionObjectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                print("✅ Đã xóa thành công \(transactionObjectIDs.count) transactions.")
            } else {
                print("Không tìm thấy transaction nào để xóa.")
            }
            
            transactionsPublisher.send([])
        } catch {
            print("❌ Lỗi khi thực hiện reset transactions: \(error)")
        }
    }
    
    // MARK: - Savings Goal Functions
    
    func fetchSavingsGoals() -> [SavingsGoal] {
        let request: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "targetDate", ascending: true)
        ]
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Lỗi khi fetch savings goals: \(error)")
            return []
        }
    }
    
    func addSavingsGoal(
        title: String,
        targetAmount: Double,
        targetDate: Date,
        iconName: String = "target",
        color: String = "blue"
    ) {
        let newGoal = SavingsGoal(context: context)
        newGoal.id = UUID()
        newGoal.title = title
        newGoal.targetAmount = targetAmount
        newGoal.currentAmount = 0
        newGoal.startDate = Date()
        newGoal.targetDate = targetDate
        newGoal.isCompleted = false
        newGoal.iconName = iconName
        newGoal.color = color
        newGoal.createAt = Date()
        newGoal.updateAt = Date()
        saveSavingsGoals()
        NotificationManager.shared.scheduleSavingsGoalExpirationNotifications(for: newGoal)
    }
    
    func updateSavingsGoal(
        _ goal: SavingsGoal,
        title: String,
        targetAmount: Double,
        targetDate: Date,
        iconName: String? = nil,
        color: String? = nil
    ) {
        goal.title = title
        goal.targetAmount = targetAmount
        goal.targetDate = targetDate
        if let iconName = iconName {
            goal.iconName = iconName
        }
        if let color = color {
            goal.color = color
        }
        goal.updateAt = Date()
        saveSavingsGoals()
        NotificationManager.shared.scheduleSavingsGoalExpirationNotifications(for: goal)
    }
    
    func deleteSavingsGoal(_ goal: SavingsGoal) {
        context.delete(goal)
        saveSavingsGoals()
    }
    
    func createTransactionForCompletedGoal(_ goal: SavingsGoal) -> Bool {
        if hasCompletedTransaction(for: goal) {
            print("⚠️ Đã có giao dịch cho mục tiêu này rồi: \(goal.title ?? "")")
            return false
        }
        
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "name == %@", "default_category_savings_goal")
        
        var savingsGoalCategory: Category?
        do {
            let categories = try context.fetch(categoryRequest)
            savingsGoalCategory = categories.first
        } catch {
            print("❌ Lỗi khi tìm category mục tiêu tiết kiệm: \(error)")
        }
        
        if savingsGoalCategory == nil {
            savingsGoalCategory = Category(context: context)
            savingsGoalCategory?.id = UUID()
            savingsGoalCategory?.name = "default_category_savings_goal"
            savingsGoalCategory?.type = "expense"
            savingsGoalCategory?.iconName = "target"
            savingsGoalCategory?.createAt = Date()
            savingsGoalCategory?.updateAt = Date()
        }
        
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.title = goal.title ?? "Mục tiêu tiết kiệm"
        transaction.amount = goal.targetAmount
        transaction.date = Date()
        transaction.type = "expense"
        transaction.category = savingsGoalCategory
        transaction.createAt = Date()
        transaction.updateAt = Date()
        transaction.note = "Hoàn thành mục tiêu tiết kiệm"
        
        saveAndRefreshData()
        print("✅ Đã tạo giao dịch cho mục tiêu hoàn thành: \(goal.title ?? "")")
        return true
    }
    
    func hasCompletedTransaction(for goal: SavingsGoal) -> Bool {
        guard let goalTitle = goal.title else { return false }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "name == %@", "default_category_savings_goal")
        
        guard let savingsGoalCategory = try? context.fetch(categoryRequest).first else {
            return false
        }
        
        request.predicate = NSPredicate(format: "category == %@ AND title == %@", savingsGoalCategory, goalTitle)
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ Lỗi khi kiểm tra giao dịch hoàn thành: \(error)")
            return false
        }
    }
    
    func updateSavingsGoalProgress(_ goal: SavingsGoal, amount: Double) {
        goal.currentAmount = amount
        goal.updateAt = Date()
        
        if hasCompletedTransaction(for: goal) {
            goal.isCompleted = true
        } else {
            if goal.currentAmount >= goal.targetAmount && !goal.isCompleted {
                goal.isCompleted = true
                if let goalTitle = goal.title {
                    NotificationManager.shared.sendSavingsGoalCompletionNotification(goalTitle: goalTitle)
                }
            }
        }
        
        saveSavingsGoals()
    }
    
    private func saveSavingsGoals() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("❌ Lỗi khi lưu savings goals: \(error)")
        }
    }
    
    // Calculate current savings from income transactions
    func calculateTotalSavings(from startDate: Date? = nil) -> Double {
        // If startDate is provided, normalize to beginning of day for accurate comparison
        // If nil, calculate from all transactions (for existing savings)
        let normalizedStartDate: Date?
        if let startDate = startDate {
            let calendar = Calendar.current
            normalizedStartDate = calendar.startOfDay(for: startDate)
        } else {
            normalizedStartDate = nil
        }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        if let startDate = normalizedStartDate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "type == %@", "income"),
                NSPredicate(format: "date >= %@", startDate as NSDate)
            ])
        } else {
            // Calculate all income transactions
            request.predicate = NSPredicate(format: "type == %@", "income")
        }
        
        do {
            let incomeTransactions = try context.fetch(request)
            let totalIncome = incomeTransactions.reduce(0.0) { sum, transaction in
                let amount = transaction.amount
                let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
                return sum + safeAmount
            }
            
            let dateStr = normalizedStartDate != nil ? 
                DateFormatter.localizedString(from: normalizedStartDate!, dateStyle: .short, timeStyle: .none) : 
                "tất cả"
            print("💰 Tổng thu nhập từ \(dateStr): \(totalIncome) (số giao dịch: \(incomeTransactions.count))")
            
            // Get all expense transactions in the same period
            let expenseRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            if let startDate = normalizedStartDate {
                expenseRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "type == %@", "expense"),
                    NSPredicate(format: "date >= %@", startDate as NSDate)
                ])
            } else {
                expenseRequest.predicate = NSPredicate(format: "type == %@", "expense")
            }
            
            let expenseTransactions = try context.fetch(expenseRequest)
            let totalExpense = expenseTransactions.reduce(0.0) { sum, transaction in
                let amount = transaction.amount
                let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
                return sum + safeAmount
            }
            
            print("💸 Tổng chi tiêu từ \(dateStr): \(totalExpense) (số giao dịch: \(expenseTransactions.count))")
            
            let savings = max(totalIncome - totalExpense, 0)
            print("💵 Tiết kiệm thực tế: \(savings)")
            
            return savings
        } catch {
            print("❌ Lỗi khi tính toán savings: \(error)")
            return 0
        }
    }
    
    // MARK: - Budget Functions
    
    func fetchBudgets() -> [Budget] {
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "createAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Lỗi khi fetch budgets: \(error)")
            return []
        }
    }
    
    func addBudget(
        categoryID: UUID?,
        amount: Double,
        period: BudgetPeriod,
        rolloverEnabled: Bool = false,
        warningThresholds: [Int] = [80, 90, 100]
    ) {
        let newBudget = Budget(context: context)
        newBudget.id = UUID()
        newBudget.categoryID = categoryID
        newBudget.amount = amount
        newBudget.period = period.rawValue
        newBudget.startDate = getPeriodStartDate(for: period)
        newBudget.isActive = true
        newBudget.rolloverEnabled = rolloverEnabled
        newBudget.createAt = Date()
        newBudget.updateAt = Date()
        
        // Encode warning thresholds to JSON
        if let data = try? JSONEncoder().encode(warningThresholds),
           let jsonString = String(data: data, encoding: .utf8) {
            newBudget.warningThresholds = jsonString
        }
        
        saveBudgets()
    }
    
    func updateBudget(
        _ budget: Budget,
        amount: Double? = nil,
        period: BudgetPeriod? = nil,
        rolloverEnabled: Bool? = nil,
        warningThresholds: [Int]? = nil
    ) {
        if let amount = amount {
            budget.amount = amount
        }
        if let period = period {
            budget.period = period.rawValue
            budget.startDate = getPeriodStartDate(for: period)
        }
        if let rolloverEnabled = rolloverEnabled {
            budget.rolloverEnabled = rolloverEnabled
        }
        if let warningThresholds = warningThresholds {
            if let data = try? JSONEncoder().encode(warningThresholds),
               let jsonString = String(data: data, encoding: .utf8) {
                budget.warningThresholds = jsonString
            }
        }
        budget.updateAt = Date()
        saveBudgets()
    }
    
    func deleteBudget(_ budget: Budget) {
        context.delete(budget)
        saveBudgets()
    }
    
    func toggleBudgetActive(_ budget: Budget) {
        budget.isActive.toggle()
        budget.updateAt = Date()
        saveBudgets()
    }
    
    func calculateSpentAmount(for budget: Budget) -> Double {
        guard let startDate = budget.startDate,
              let endDate = budget.currentPeriodEndDate else {
            return 0
        }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "type == %@", "expense"),
            NSPredicate(format: "date >= %@", startDate as NSDate),
            NSPredicate(format: "date < %@", endDate as NSDate)
        ]
        
        // Nếu có categoryID, chỉ tính cho category đó
        // Nếu nil, tính tổng tất cả expense (ngân sách tổng)
        if let categoryID = budget.categoryID {
            // Tìm category từ ID
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
            
            if let category = try? context.fetch(categoryRequest).first {
                predicates.append(NSPredicate(format: "category == %@", category))
            } else {
                return 0 // Category không tồn tại
            }
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            let transactions = try context.fetch(request)
            return transactions.reduce(0) { sum, transaction in
                let amount = transaction.amount
                let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
                return sum + safeAmount
            }
        } catch {
            print("❌ Lỗi khi tính toán spent amount: \(error)")
            return 0
        }
    }
    
    func updateAllBudgetsSpentAmount() {
        let budgets = fetchBudgets()
        for budget in budgets {
            let spent = calculateSpentAmount(for: budget)
            // Lưu spent amount vào một property tạm thời hoặc tính toán real-time
            // Vì spentAmount là computed property, không cần lưu
        }
    }
    
    // Kiểm tra và cập nhật kỳ ngân sách (reset hoặc rollover)
    func updateBudgetPeriods() {
        let budgets = fetchBudgets()
        let calendar = Calendar.current
        
        for budget in budgets {
            guard let startDate = budget.startDate,
                  let endDate = budget.currentPeriodEndDate,
                  Date() >= endDate else {
                continue // Chưa hết kỳ
            }
            
            if budget.rolloverEnabled {
                // Rollover: Chuyển số tiền còn lại sang kỳ mới
                let spent = calculateSpentAmount(for: budget)
                
                // Validate tất cả giá trị trước khi tính toán
                let safeAmount = budget.amount.isFinite && !budget.amount.isNaN && budget.amount >= 0 ? budget.amount : 0
                let safeSpent = spent.isFinite && !spent.isNaN && spent >= 0 ? spent : 0
                
                let remaining = max(safeAmount - safeSpent, 0)
                let newAmount = safeAmount + remaining
                
                // Validate kết quả trước khi gán
                if newAmount.isFinite && !newAmount.isNaN && newAmount >= 0 {
                    budget.amount = newAmount
                }
            }
            
            // Reset startDate cho kỳ mới
            budget.startDate = getPeriodStartDate(for: budget.budgetPeriod)
            budget.updateAt = Date()
        }
        
        saveBudgets()
    }
    
    private func getPeriodStartDate(for period: BudgetPeriod) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components) ?? now
        case .quarterly:
            let month = calendar.component(.month, from: now)
            let quarter = (month - 1) / 3
            let quarterStartMonth = quarter * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            return calendar.date(from: components) ?? now
        case .yearly:
            let components = calendar.dateComponents([.year], from: now)
            return calendar.date(from: components) ?? now
        }
    }
    
    private func saveBudgets() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            // Notify that budgets changed
            NotificationCenter.default.post(name: NSNotification.Name("BudgetDidChange"), object: nil)
        } catch {
            print("❌ Lỗi khi lưu budgets: \(error)")
        }
    }
    
    // MARK: - Recurring Transaction Functions
    
    func fetchRecurringTransactions() -> [RecurringTransaction] {
        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(key: "nextDueDate", ascending: true),
            NSSortDescriptor(key: "createAt", ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Lỗi khi fetch recurring transactions: \(error)")
            return []
        }
    }
    
    func addRecurringTransaction(
        title: String,
        amount: Double,
        type: String,
        categoryID: UUID?,
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date? = nil,
        note: String? = nil
    ) {
        let newRecurring = RecurringTransaction(context: context)
        newRecurring.id = UUID()
        newRecurring.title = title
        newRecurring.amount = amount
        newRecurring.type = type
        newRecurring.categoryID = categoryID
        newRecurring.frequency = frequency.rawValue
        newRecurring.startDate = startDate
        newRecurring.endDate = endDate
        newRecurring.note = note
        newRecurring.isActive = true
        newRecurring.createAt = Date()
        newRecurring.updateAt = Date()
        
        // Tính nextDueDate từ startDate
        newRecurring.nextDueDate = calculateNextDueDate(from: startDate, frequency: frequency, endDate: endDate)
        
        saveRecurringTransactions()
    }
    
    func updateRecurringTransaction(
        _ recurring: RecurringTransaction,
        title: String? = nil,
        amount: Double? = nil,
        type: String? = nil,
        categoryID: UUID? = nil,
        frequency: RecurringFrequency? = nil,
        startDate: Date? = nil,
        endDate: Date?? = nil,
        note: String?? = nil
    ) {
        if let title = title {
            recurring.title = title
        }
        if let amount = amount {
            recurring.amount = amount
        }
        if let type = type {
            recurring.type = type
        }
        if let categoryID = categoryID {
            recurring.categoryID = categoryID
        }
        if let frequency = frequency {
            recurring.frequency = frequency.rawValue
        }
        if let startDate = startDate {
            recurring.startDate = startDate
        }
        if let endDate = endDate {
            recurring.endDate = endDate
        }
        if let note = note {
            recurring.note = note
        }
        
        // Cập nhật nextDueDate nếu cần
        if let frequency = frequency ?? RecurringFrequency(rawValue: recurring.frequency ?? "monthly"),
           let startDate = startDate ?? recurring.startDate {
            recurring.nextDueDate = calculateNextDueDate(from: startDate, frequency: frequency, endDate: recurring.endDate)
        }
        
        recurring.updateAt = Date()
        saveRecurringTransactions()
    }
    
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) {
        context.delete(recurring)
        saveRecurringTransactions()
    }
    
    func toggleRecurringTransactionActive(_ recurring: RecurringTransaction) {
        recurring.isActive.toggle()
        recurring.updateAt = Date()
        saveRecurringTransactions()
    }
    
    private func calculateNextDueDate(from startDate: Date, frequency: RecurringFrequency, endDate: Date?) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        
        // Nếu startDate là trong tương lai, đó chính là nextDueDate
        if start >= today {
            // Kiểm tra endDate
            if let endDate = endDate {
                let endDateStart = calendar.startOfDay(for: endDate)
                if start > endDateStart {
                    return nil
                }
            }
            return start
        }
        
        // Nếu startDate là trong quá khứ, tính ngày tiếp theo theo chu kỳ
        // Tính số chu kỳ cần thiết để đạt đến hôm nay hoặc sau hôm nay
        var nextDate = start
        var cycles = 0
        
        // Tính từng chu kỳ cho đến khi >= hôm nay
        while nextDate < today {
            cycles += 1
            switch frequency {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: cycles, to: start) ?? nextDate
            case .weekly:
                // Sử dụng WeekStartSettings để tính tuần theo ngày bắt đầu tuần đã chọn
                nextDate = WeekStartSettings.shared.addWeeks(cycles, to: start)
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: cycles, to: start) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: cycles, to: start) ?? nextDate
            }
            
            // Kiểm tra endDate
            if let endDate = endDate {
                let endDateStart = calendar.startOfDay(for: endDate)
                if nextDate > endDateStart {
                    return nil
                }
            }
            
            // Tránh vòng lặp vô hạn (tối đa 100 năm)
            if cycles > (frequency == .daily ? 36500 : frequency == .weekly ? 5200 : frequency == .monthly ? 1200 : 100) {
                return nil
            }
        }
        
        // nextDate bây giờ >= today, đó chính là ngày đến hạn tiếp theo
        return nextDate
    }
    
    // Kiểm tra và tạo transactions từ recurring transactions đã đến hạn
    func processDueRecurringTransactions() {
        let recurringTransactions = fetchRecurringTransactions()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        print("🔄 Xử lý recurring transactions - Hôm nay: \(today)")
        
        for recurring in recurringTransactions {
            guard let nextDueDate = recurring.nextDueDate,
                  let startDate = recurring.startDate else {
                print("⚠️ Recurring transaction thiếu nextDueDate hoặc startDate")
                continue
            }
            
            // Kiểm tra xem đã đến hạn chưa
            let dueDate = calendar.startOfDay(for: nextDueDate)
            
            print("📅 Kiểm tra: \(recurring.title ?? "") - NextDueDate: \(dueDate), Today: \(today)")
            
            if dueDate <= today {
                print("✅ Đã đến hạn! Tạo transaction cho: \(recurring.title ?? "")")
                
                // Tạo transaction từ recurring transaction
                createTransactionFromRecurring(recurring, date: nextDueDate)
                
                // Cập nhật nextDueDate cho lần tiếp theo
                // Tính từ nextDueDate hiện tại (không phải từ startDate)
                let currentDueDate = nextDueDate
                var newNextDate: Date?
                
                switch recurring.transactionFrequency {
                case .daily:
                    newNextDate = calendar.date(byAdding: .day, value: 1, to: currentDueDate)
                case .weekly:
                    // Sử dụng WeekStartSettings để tính tuần theo ngày bắt đầu tuần đã chọn
                    newNextDate = WeekStartSettings.shared.addWeeks(1, to: currentDueDate)
                case .monthly:
                    newNextDate = calendar.date(byAdding: .month, value: 1, to: currentDueDate)
                case .yearly:
                    newNextDate = calendar.date(byAdding: .year, value: 1, to: currentDueDate)
                }
                
                // Kiểm tra endDate
                if let endDate = recurring.endDate {
                    let endDateStart = calendar.startOfDay(for: endDate)
                    if let newDate = newNextDate, newDate > endDateStart {
                        print("❌ Đã vượt quá endDate, deactivate")
                        recurring.isActive = false
                        newNextDate = nil
                    }
                }
                
                if let newDate = newNextDate {
                    recurring.nextDueDate = newDate
                    print("✅ Cập nhật nextDueDate thành: \(newDate)")
                } else {
                    // Không còn ngày nào nữa, deactivate
                    recurring.isActive = false
                    print("❌ Không còn ngày nào nữa, deactivate")
                }
                
                recurring.updateAt = Date()
            } else {
                print("⏳ Chưa đến hạn, còn \(calendar.dateComponents([.day], from: today, to: dueDate).day ?? 0) ngày")
            }
        }
        
        saveRecurringTransactions()
        print("✅ Hoàn thành xử lý recurring transactions")
    }
    
    private func createTransactionFromRecurring(_ recurring: RecurringTransaction, date: Date) {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.title = recurring.title ?? "Giao dịch định kỳ"
        
        // Validate amount trước khi gán để tránh NaN/Infinite
        let safeAmount = recurring.amount.isFinite && !recurring.amount.isNaN && recurring.amount >= 0 
            ? recurring.amount 
            : 0
        newTransaction.amount = safeAmount
        
        newTransaction.type = recurring.type ?? "expense"
        newTransaction.date = date
        newTransaction.note = recurring.note
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        // Gán category nếu có
        if let categoryID = recurring.categoryID {
            if let category = fetchCategory(by: categoryID) {
                newTransaction.category = category
            }
        }
        
        // Lưu transaction
        saveAndRefreshData()
    }
    
    private func saveRecurringTransactions() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            // Notify that recurring transactions changed
            NotificationCenter.default.post(name: NSNotification.Name("RecurringTransactionDidChange"), object: nil)
        } catch {
            print("❌ Lỗi khi lưu recurring transactions: \(error)")
        }
    }
}
