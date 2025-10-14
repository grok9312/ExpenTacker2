//
//  ExpenseDataManager.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/1.
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

// 資料管理器 - 負責處理記帳記錄的儲存和讀取
class ExpenseDataManager: ObservableObject {
    @Published var expenses: [ExpenseRecord] = []
    @Published var categories: [ExpenseCategory] = []
    
    // 改用文件系統儲存，更適合大量資料
    private let fileManager = FileManager.default
    private let expensesFileName = "expenses.json"
    private let categoriesFileName = "categories.json"
    private let imagesDirectoryName = "ExpenseImages"
    
    // 獲取文件路徑
    private var expensesFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(expensesFileName)
    }
    
    private var categoriesFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(categoriesFileName)
    }
    
    private var imagesDirectoryURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = documentsPath.appendingPathComponent(imagesDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    init() {
        loadCategories()
        loadExpenses()
        // 移除自動產生假資料的程式碼
    }
    
    // MARK: - 分類管理
    
    // 載入分類
    func loadCategories() {
        do {
            // 檢查文件是否存在
            guard fileManager.fileExists(atPath: categoriesFileURL.path) else {
                print("分類文件不存在，創建預設分類")
                createDefaultCategories()
                return
            }
            
            let data = try Data(contentsOf: categoriesFileURL)
            let decodedCategories = try JSONDecoder().decode([ExpenseCategory].self, from: data)
            self.categories = decodedCategories
            print("成功載入 \(categories.count) 個分類")
        } catch {
            print("載入分類失敗: \(error)")
            createDefaultCategories()
        }
    }
    
    // 建立預設分類
    private func createDefaultCategories() {
        categories = [ExpenseCategory.noneCategory] +
                    ExpenseCategory.defaultIncomeCategories +
                    ExpenseCategory.defaultExpenseCategories
        saveCategories()
    }
    
    // 儲存分類
    private func saveCategories() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(categories)
            try data.write(to: categoriesFileURL)
            print("成功儲存 \(categories.count) 個分類")
        } catch {
            print("儲存分類失敗: \(error)")
        }
    }
    
    // 新增分類
    func addCategory(_ category: ExpenseCategory) {
        categories.append(category)
        saveCategories()
    }
    
    // 更新分類
    func updateCategory(_ category: ExpenseCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    // 刪除分類
    func deleteCategory(_ category: ExpenseCategory) {
        // 不能刪除預設的none分類
        guard !category.isDefault else { return }
        
        // 將使用此分類的記錄改為none
        for i in 0..<expenses.count {
            if expenses[i].categoryId == category.id {
                expenses[i].categoryId = nil // 設為nil表示none分類
            }
        }
        
        // 刪除分類
        categories.removeAll { $0.id == category.id }
        
        // 儲存變更
        saveCategories()
        saveExpenses()
    }
    
    // 根據類型獲取分類
    func getCategories(for type: TransactionType) -> [ExpenseCategory] {
        return categories.filter { $0.type == type || $0.type == .all }
    }
    
    // 根據ID獲取分類
    func getCategory(by id: String?) -> ExpenseCategory {
        guard let id = id,
              let category = categories.first(where: { $0.id == id }) else {
            return ExpenseCategory.noneCategory
        }
        return category
    }
    
    // MARK: - 資料載入
    func loadExpenses() {
        do {
            // 檢查文件是否存在
            guard fileManager.fileExists(atPath: expensesFileURL.path) else {
                print("記帳文件不存在，創建新的空陣列")
                self.expenses = []
                return
            }
            
            let data = try Data(contentsOf: expensesFileURL)
            let decodedExpenses = try JSONDecoder().decode([ExpenseRecord].self, from: data)
            self.expenses = decodedExpenses.sorted { $0.date > $1.date } // 按日期降序排列
            print("成功載入 \(expenses.count) 筆記帳記錄")
        } catch {
            print("載入記帳記錄失敗: \(error)")
            self.expenses = []
        }
    }
    
    // MARK: - 資料儲存
    private func saveExpenses() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // 讓JSON格式更易讀
            let data = try encoder.encode(expenses)
            try data.write(to: expensesFileURL)
            print("成功儲存 \(expenses.count) 筆記帳記錄")
            syncExpensesToWidget() // 新增：同步到Widget
            WidgetCenter.shared.reloadAllTimelines() // 新增：通知Widget刷新
        } catch {
            print("儲存記帳記錄失敗: \(error)")
        }
    }
    
    private func syncExpensesToWidget() {
        let groupID = "group.com.YuMei.expentacker2" // Unified App Group ID shared with widget
        guard let userDefaults = UserDefaults(suiteName: groupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        // Map ExpenseRecord to ExpenseRecordWidget
        let widgetRecords = expenses.map { exp in
            ExpenseRecordWidget(amount: exp.amount, date: exp.date, type: exp.type.rawValue)
        }
        if let data = try? encoder.encode(widgetRecords) {
            userDefaults.set(data, forKey: "expenses")
        }
    }
    
    // MARK: - 新增記錄
    func addExpense(_ expense: ExpenseRecord) {
        expenses.append(expense)
        expenses.sort { $0.date > $1.date } // 重新排序
        saveExpenses()
    }
    
    // MARK: - 更新記錄
    func updateExpense(_ expense: ExpenseRecord) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            expenses.sort { $0.date > $1.date } // 重新排序
            saveExpenses()
        }
    }
    
    // MARK: - 刪除記錄
    func deleteExpense(_ expense: ExpenseRecord) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }
    
    func deleteExpense(at indexSet: IndexSet) {
        expenses.remove(atOffsets: indexSet)
        saveExpenses()
    }
    
    // MARK: - 統計功能
    
    // 計算總收入
    var totalIncome: Double {
        expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    // 計算總支出
    var totalExpense: Double {
        expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    // 計算餘額
    var balance: Double {
        totalIncome - totalExpense
    }
    
    // MARK: - 當月統計功能
    
    // 獲取當月第一天和最後一天
    private var currentMonthDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // 當月第一天
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // 當月最後一天
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end.addingTimeInterval(-1) ?? now
        
        return (startOfMonth, endOfMonth)
    }
    
    // 格式化當月日期範圍顯示
    var currentMonthDateRangeText: String {
        let dateRange = currentMonthDateRange
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M月dd日"
        
        let startDateText = formatter.string(from: dateRange.start)
        let endDateText = formatter.string(from: dateRange.end)
        
        return "\(startDateText) - \(endDateText)"
    }
    
    // 當月總收入
    var currentMonthIncome: Double {
        let dateRange = currentMonthDateRange
        return expenses.filter { expense in
            expense.type == .income &&
            expense.date >= dateRange.start &&
            expense.date <= dateRange.end
        }.reduce(0) { $0 + $1.amount }
    }
    
    // 當月總支出
    var currentMonthExpense: Double {
        let dateRange = currentMonthDateRange
        return expenses.filter { expense in
            expense.type == .expense &&
            expense.date >= dateRange.start &&
            expense.date <= dateRange.end
        }.reduce(0) { $0 + $1.amount }
    }
    
    // 當月餘額
    var currentMonthBalance: Double {
        currentMonthIncome - currentMonthExpense
    }
    
    // 格式化當月餘額 (考慮正負號和顏色)
    var formattedCurrentMonthBalance: (text: String, color: Color) {
        let balanceValue = currentMonthBalance
        let formattedText = formatAmount(abs(balanceValue))
        
        if balanceValue > 0 {
            return ("+\(formattedText)", .green)
        } else if balanceValue < 0 {
            return ("-\(formattedText)", .red)
        } else {
            return (formattedText, .primary)
        }
    }
    
    // 根據類型篩選記錄
    func getExpenses(by type: TransactionType) -> [ExpenseRecord] {
        if type == .all {
            return expenses
        }
        return expenses.filter { $0.type == type }
    }
    
    // 根據日期範圍篩選記錄
    func getExpenses(from startDate: Date, to endDate: Date) -> [ExpenseRecord] {
        return expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
    }
    
    // 根據月份篩選記錄
    func getExpenses(for month: Int, year: Int) -> [ExpenseRecord] {
        return expenses.filter { expense in
            let calendar = Calendar.current
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseMonth == month && expenseYear == year
        }
    }
    
    // 搜尋記錄 (根據備註)
    func searchExpenses(with searchText: String) -> [ExpenseRecord] {
        if searchText.isEmpty {
            return expenses
        }
        return expenses.filter { expense in
            expense.remark.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - 資料清除 (用於測試或重置)
    func clearAllExpenses() {
        expenses.removeAll()
        try? fileManager.removeItem(at: expensesFileURL) // 刪除檔案
    }
    
    func clearAllCategories() {
        categories.removeAll()
        try? fileManager.removeItem(at: categoriesFileURL) // 刪除分類檔案
        createDefaultCategories() // 重新建立預設分類
    }
    
    // MARK: - 格式化方法
    
    // 格式化金額
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "NT$0"
    }
    
    // 格式化餘額 (考慮正負號和顏色)
    var formattedBalance: (text: String, color: Color) {
        let balanceValue = balance
        let formattedText = formatAmount(abs(balanceValue))
        
        if balanceValue > 0 {
            return ("+\(formattedText)", .green)
        } else if balanceValue < 0 {
            return ("-\(formattedText)", .red)
        } else {
            return (formattedText, .primary)
        }
    }
    
    // MARK: - 圖片儲存/讀取
    
    func saveImageData(_ data: Data) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            print("成功儲存圖片: \(filename)")
            return filename
        } catch {
            print("儲存圖片失敗: \(error)")
            return nil
        }
    }
    
    func loadImage(for filename: String?) -> UIImage? {
        guard let filename = filename else { return nil }
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteImage(filename: String?) {
        guard let filename = filename else { return }
        let url = imagesDirectoryURL.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }
}

// Widget同步用的結構
fileprivate struct ExpenseRecordWidget: Codable {
    let amount: Double
    let date: Date
    let type: String // "expense" or "income"
}
