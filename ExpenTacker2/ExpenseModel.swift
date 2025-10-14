//
//  ExpenseModel.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/1.
//

import SwiftUI
import Foundation

// 交易類型枚舉
enum TransactionType: String, CaseIterable, Codable {
    case income = "income"
    case expense = "expense"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .income:
            return "收入"
        case .expense:
            return "支出"
        case .all:
            return "全部"
        }
    }
    
    var iconName: String {
        switch self {
        case .income:
            return "plus.circle.fill"
        case .expense:
            return "minus.circle.fill"
        case .all:
            return "circle.fill"
        }
    }
}

// 記帳記錄模型
struct ExpenseRecord: Identifiable, Codable {
    let id = UUID()
    var remark: String          // 備註
    var amount: Double          // 金額
    var date: Date             // 日期
    var type: TransactionType  // 類型
    var color: Color           // 顏色
    var categoryId: String?    // 分類ID，可以為空(表示none)
    var photoFilename: String? // 照片檔名(可選)
    
    // 自定義初始化器
    init(remark: String, amount: Double, date: Date = Date(), type: TransactionType, color: Color = .blue, categoryId: String? = nil, photoFilename: String? = nil) {
        self.remark = remark
        self.amount = amount
        self.date = date
        self.type = type
        self.color = color
        self.categoryId = categoryId
        self.photoFilename = photoFilename
    }
    
    // 格式化金額顯示
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.maximumFractionDigits = 0
        
        let prefix = type == .expense ? "-" : "+"
        let formattedNumber = formatter.string(from: NSNumber(value: abs(amount))) ?? "NT$0"
        
        return prefix + formattedNumber
    }
    
    // 格式化日期顯示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// Color 的 Codable 擴展
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        guard let components = UIColor(self).cgColor.components else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Cannot get color components"))
        }
        
        try container.encode(Double(components[0]), forKey: .red)
        try container.encode(Double(components[1]), forKey: .green)
        try container.encode(Double(components[2]), forKey: .blue)
        try container.encode(Double(components.count > 3 ? components[3] : 1.0), forKey: .alpha)
    }
}

// 預設顏色選項
extension Color {
    static let expenseColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray
    ]
}

// 分類模型
struct ExpenseCategory: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var color: Color
    var type: TransactionType // 收入或支出分類
    var isDefault: Bool = false // 是否為預設分類(none)
    
    init(id: String = UUID().uuidString, name: String, color: Color, type: TransactionType, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.type = type
        self.isDefault = isDefault
    }
    
    // 預設的none分類
    static let noneCategory = ExpenseCategory(
        id: "none",
        name: "無分類",
        color: .gray,
        type: .all,
        isDefault: true
    )
    
    // 預設收入分類
    static let defaultIncomeCategories = [
        ExpenseCategory(name: "薪水", color: .green, type: .income),
        ExpenseCategory(name: "副業", color: .blue, type: .income),
        ExpenseCategory(name: "投資", color: .purple, type: .income),
        ExpenseCategory(name: "其他收入", color: .mint, type: .income)
    ]
    
    // 預設支出分類
    static let defaultExpenseCategories = [
        ExpenseCategory(name: "餐飲", color: .red, type: .expense),
        ExpenseCategory(name: "交通", color: .orange, type: .expense),
        ExpenseCategory(name: "購物", color: .pink, type: .expense),
        ExpenseCategory(name: "娛樂", color: .yellow, type: .expense),
        ExpenseCategory(name: "生活用品", color: .brown, type: .expense),
        ExpenseCategory(name: "其他支出", color: .gray, type: .expense)
    ]
}
