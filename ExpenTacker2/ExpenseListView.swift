//
//  ExpenseListView.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/1.
//

import SwiftUI
import Charts

struct ExpenseListView: View {
    @ObservedObject var dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategoryId: String? = nil
    @State private var selectedDateFilter: DateFilter = .thisMonth
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showingChart = false
    @State private var showingEditExpense = false
    @State private var editingExpense: ExpenseRecord? = nil
    
    enum DateFilter: String, CaseIterable {
        case today = "今天"
        case thisWeek = "本週"
        case thisMonth = "本月"
        case last30Days = "近30天"
        case thisYear = "今年"
        case custom = "自訂範圍"
    }
    
    private var availableCategories: [ExpenseCategory] {
        let base: [ExpenseCategory]
        if selectedType == .all {
            base = dataManager.categories
        } else {
            base = dataManager.getCategories(for: selectedType)
        }
        return base.filter { !$0.isDefault }
    }
    
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateFilter {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            return (startOfDay, endOfDay)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
            return (startOfWeek, endOfWeek)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            return (startOfMonth, endOfMonth)
        case .last30Days:
            // 修改為以當前日期為中心的前後15天
            let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: now) ?? now
            let fifteenDaysLater = calendar.date(byAdding: .day, value: 15, to: now) ?? now
            return (calendar.startOfDay(for: fifteenDaysAgo), calendar.startOfDay(for: fifteenDaysLater))
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? now
            return (startOfYear, endOfYear)
        case .custom:
            return (customStartDate, customEndDate)
        }
    }
    
    private var filteredExpenses: [ExpenseRecord] {
        let byType: [ExpenseRecord]
        switch selectedType {
        case .all:
            byType = dataManager.expenses
        case .income:
            byType = dataManager.expenses.filter { $0.type == .income }
        case .expense:
            byType = dataManager.expenses.filter { $0.type == .expense }
        }
        
        let byCategory: [ExpenseRecord]
        if let catId = selectedCategoryId {
            byCategory = byType.filter { $0.categoryId == catId }
        } else {
            byCategory = byType
        }
        
        // 日期篩選
        let range = dateRange
        return byCategory.filter { expense in
            expense.date >= range.start && expense.date < range.end
        }
    }
    
    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var averageAmount: Double {
        guard !filteredExpenses.isEmpty else { return 0 }
        return totalAmount / Double(filteredExpenses.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 篩選器區域
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 12) {
                        filterSection
                        
                        if selectedDateFilter == .custom {
                            customDateSection
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                
                // 內容區域 - 列表或圖表
                if showingChart {
                    chartView
                } else {
                    expenseListView
                }
            }
            .navigationTitle("消費分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingChart ? "列表" : "圖表") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingChart.toggle()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - 篩選器區域
    private var filterSection: some View {
        VStack(spacing: 10) {
            // 交易類型
            HStack {
                Text("類型").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Picker("類型", selection: $selectedType) {
                    Text("全部").tag(TransactionType.all)
                    Text("收入").tag(TransactionType.income)
                    Text("支出").tag(TransactionType.expense)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
                .onChange(of: selectedType) { _, _ in
                    selectedCategoryId = nil
                }
            }
            
            // 日期篩選
            HStack {
                Text("時間").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Picker("日期", selection: $selectedDateFilter) {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 260)
            }
            
            // 分類篩選
            HStack {
                Text("分類").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Picker("分類", selection: $selectedCategoryId) {
                    Text("全部").tag(String?.none)
                    ForEach(availableCategories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 260)
            }
        }
    }
    
    // MARK: - 自訂日期區域
    private var customDateSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("開始日期")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                DatePicker("", selection: $customStartDate, displayedComponents: .date)
                    .labelsHidden()
            }
            
            HStack {
                Text("結束日期")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                DatePicker("", selection: $customEndDate, displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 列表視圖
    private var expenseListView: some View {
        Group {
            if filteredExpenses.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("沒有符合條件的記錄")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("嘗試調整篩選條件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredExpenses) { expense in
                        NavigationLink(destination: ExpenseDetailView(dataManager: dataManager, expense: expense)) {
                            ExpenseRowView(expense: expense, dataManager: dataManager)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                editingExpense = expense
                                showingEditExpense = true
                            } label: {
                                Label("編輯", systemImage: "pencil")
                            }
                            .tint(.blue)
                            Button(role: .destructive) {
                                dataManager.deleteExpense(expense)
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .sheet(isPresented: $showingEditExpense) {
                    if let editingExpense = editingExpense {
                        EditExpenseView(dataManager: dataManager, expense: editingExpense)
                    }
                }
            }
        }
    }
    
    // MARK: - 圖表視圖
    private var chartView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !filteredExpenses.isEmpty {
                    // 區間消費分析長條圖 (僅保留此圖)
                    intervalAnalysisBarChart
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 區間消費分析長條圖 (新增)
    private var intervalAnalysisBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("區間消費分析")
                    .font(.headline)
                Spacer()
                Text("按\(intervalTypeDescription)統計")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 橫向滾動的 BarChart
            let barWidth: CGFloat = 44
            let chartWidth = max(UIScreen.main.bounds.width - 32, barWidth * CGFloat(intervalData.count))
            ScrollView(.horizontal, showsIndicators: intervalData.count > 7) {
                Chart {
                    ForEach(intervalData) { item in
                        let barColor: Color = {
                            if selectedType == .all {
                                return item.amount < 0 ? .red : .blue // 負值紅色，正值藍色
                            } else {
                                return selectedType == .income ? .green : .red
                            }
                        }()
                        BarMark(
                            x: .value("時間", item.period),
                            y: .value("金額", item.amount)
                        )
                        .foregroundStyle(barColor)
                        .opacity(0.8)
                        .cornerRadius(4)
                    }
                }
                .frame(width: chartWidth, height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatAxisAmount(amount))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let period = value.as(String.self) {
                                Text(period)
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            // 統計摘要
           
        }
    }
    
    // MARK: - 資料處理
    // MARK: - 區間分析資料處理 (新增)
    // 解決 Swift generic tuple Hashable 問題
    private struct GroupKey<T: Hashable>: Hashable {
        let period: T
        let type: TransactionType
    }

    private var intervalData: [IntervalChartData] {
        let calendar = Calendar.current
        let range = dateRange
        var intervals: [IntervalChartData] = []
        
        func groupAndMap<T: Hashable>(by: (ExpenseRecord) -> T, periodString: (T) -> String) -> [IntervalChartData] {
            if selectedType == .all {
                let grouped = Dictionary(grouping: filteredExpenses, by: by)
                return grouped.map { (key, expenses) in
                    let income = expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let expense = expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    return IntervalChartData(
                        period: periodString(key),
                        amount: income - expense,
                        type: .all
                    )
                }
            } else {
                let grouped = Dictionary(grouping: filteredExpenses, by: by)
                return grouped.map { (key, expenses) in
                    IntervalChartData(
                        period: periodString(key),
                        amount: expenses.reduce(0) { $0 + $1.amount },
                        type: selectedType
                    )
                }
            }
        }
        
        switch selectedDateFilter {
        case .today:
            intervals = groupAndMap(by: { calendar.component(.hour, from: $0.date) }, periodString: { "\($0):00" })
            intervals.sort { Int($0.period.prefix(2)) ?? 0 < Int($1.period.prefix(2)) ?? 0 }
        case .thisWeek, .last30Days, .thisMonth:
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            // Generate all days in range (inclusive)
            var allDays: [Date] = []
            var current = calendar.startOfDay(for: range.start)
            let end = calendar.startOfDay(for: range.end)
            while current <= end {
                allDays.append(current)
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            }
            let grouped = Dictionary(grouping: filteredExpenses, by: { calendar.startOfDay(for: $0.date) })
            intervals = allDays.map { day in
                let expenses = grouped[day] ?? []
                if selectedType == .all {
                    let income = expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let expense = expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    return IntervalChartData(
                        period: formatter.string(from: day),
                        amount: income - expense,
                        type: .all
                    )
                } else {
                    return IntervalChartData(
                        period: formatter.string(from: day),
                        amount: expenses.reduce(0) { $0 + $1.amount },
                        type: selectedType
                    )
                }
            }
            intervals.sort {
                let f = DateFormatter(); f.dateFormat = "MM/dd"
                return f.date(from: $0.period) ?? Date() < f.date(from: $1.period) ?? Date()
            }
        case .thisYear:
            // 顯示1~12月，若無資料則金額為0
            let months = Array(1...12)
            let grouped = Dictionary(grouping: filteredExpenses, by: { calendar.component(.month, from: $0.date) })
            intervals = months.map { month in
                let expenses = grouped[month] ?? []
                if selectedType == .all {
                    let income = expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let expense = expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    return IntervalChartData(
                        period: "\(month)月",
                        amount: income - expense,
                        type: .all
                    )
                } else {
                    return IntervalChartData(
                        period: "\(month)月",
                        amount: expenses.reduce(0) { $0 + $1.amount },
                        type: selectedType
                    )
                }
            }
        case .custom:
            let daysDifference = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 0
            if daysDifference < 92 { // 小於3個月
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd"
                var allDays: [Date] = []
                var current = calendar.startOfDay(for: range.start)
                let end = calendar.startOfDay(for: range.end)
                while current <= end {
                    allDays.append(current)
                    current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
                }
                let grouped = Dictionary(grouping: filteredExpenses, by: { calendar.startOfDay(for: $0.date) })
                intervals = allDays.map { day in
                    let expenses = grouped[day] ?? []
                    if selectedType == .all {
                        let income = expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                        let expense = expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                        return IntervalChartData(
                            period: formatter.string(from: day),
                            amount: income - expense,
                            type: .all
                        )
                    } else {
                        return IntervalChartData(
                            period: formatter.string(from: day),
                            amount: expenses.reduce(0) { $0 + $1.amount },
                            type: selectedType
                        )
                    }
                }
                intervals.sort {
                    let f = DateFormatter(); f.dateFormat = "MM/dd"
                    return f.date(from: $0.period) ?? Date() < f.date(from: $1.period) ?? Date()
                }
            } else if daysDifference < 183 { // 3-6個月
                // 以週為單位，確保生成所有週的資料點
                var allWeeks: [(year: Int, week: Int)] = []
                var current = calendar.startOfDay(for: range.start)
                let end = calendar.startOfDay(for: range.end)
                var seen = Set<String>()
                
                // 確保包含結束日期所在的週 - 修正邊界條件
                while current < end {
                    let year = calendar.component(.yearForWeekOfYear, from: current)
                    let week = calendar.component(.weekOfYear, from: current)
                    let key = "\(year)-\(week)"
                    if !seen.contains(key) {
                        allWeeks.append((year, week))
                        seen.insert(key)
                    }
                    current = calendar.date(byAdding: .day, value: 7, to: current) ?? current
                }
                
                // 確保包含結束日期所在的週
                let endYear = calendar.component(.yearForWeekOfYear, from: end)
                let endWeek = calendar.component(.weekOfYear, from: end)
                let endKey = "\(endYear)-\(endWeek)"
                if !seen.contains(endKey) {
                    allWeeks.append((endYear, endWeek))
                }
                
                // 按年份和週數排序
                allWeeks.sort { (first, second) in
                    if first.year != second.year {
                        return first.year < second.year
                    }
                    return first.week < second.week
                }
                
                let grouped = Dictionary(grouping: filteredExpenses, by: { "\(calendar.component(.yearForWeekOfYear, from: $0.date))-\(calendar.component(.weekOfYear, from: $0.date))" })
                intervals = allWeeks.map { (year, week) in
                    let key = "\(year)-\(week)"
                    let expenses = grouped[key] ?? []
                    // 修正標籤格式，包含年份資訊以避免混淆
                    let label = year == Calendar.current.component(.year, from: Date()) ? "W\(week)" : "\(String(year).suffix(2))W\(week)"
                    if selectedType == .all {
                        let income = expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                        let expense = expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                        return IntervalChartData(
                            period: label,
                            amount: income - expense,
                            type: .all
                        )
                    } else {
                        return IntervalChartData(
                            period: label,
                            amount: expenses.reduce(0) { $0 + $1.amount },
                            type: selectedType
                        )
                    }
                }
            } else { // 6個月以上
                // 以月為單位
                var allMonths: [(year: Int, month: Int)] = []
                var current = calendar.date(from: calendar.dateComponents([.year, .month], from: range.start)) ?? range.start
                let end = calendar.date(from: calendar.dateComponents([.year, .month], from: range.end)) ?? range.end
                while current <= end {
                    let year = calendar.component(.year, from: current)
                    let month = calendar.component(.month, from: current)
                    allMonths.append((year, month))
                    current = calendar.date(byAdding: .month, value: 1, to: current) ?? current
                }
                let grouped = Dictionary(grouping: filteredExpenses, by: { "\(calendar.component(.year, from: $0.date))_\(calendar.component(.month, from: $0.date))" })
                intervals = allMonths.map { (year, month) in
                    let key = "\(year)_\(month)"
                    let expenses = grouped[key] ?? []
                    let label = "\(month)月"
                    if selectedType == .all {
                        let income = expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                        let expense = expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                        return IntervalChartData(
                            period: label,
                            amount: income - expense,
                            type: .all
                        )
                    } else {
                        return IntervalChartData(
                            period: label,
                            amount: expenses.reduce(0) { $0 + $1.amount },
                            type: selectedType
                        )
                    }
                }
            }
        }
        return intervals
    }
    
    // MARK: - 區間分析輔助屬性
    private var intervalTypeDescription: String {
        switch selectedDateFilter {
        case .today: return "小時"
        case .thisWeek, .last30Days: return "日"
        case .thisMonth: return "日"
        case .thisYear: return "月"
        case .custom:
            let calendar = Calendar.current
            let range = dateRange
            let daysDifference = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 0
            if daysDifference < 92 { return "日" }
            else if daysDifference < 183 { return "週" }
            else { return "月" }
        }
    }
    
    private var maxIntervalAmount: Double {
        intervalData.map { $0.amount }.max() ?? 0
    }
    
    private var avgIntervalAmount: Double {
        guard !intervalData.isEmpty else { return 0 }
        return intervalData.map { $0.amount }.reduce(0, +) / Double(intervalData.count)
    }
    
    private var totalIntervalAmount: Double {
        intervalData.map { $0.amount }.reduce(0, +)
    }
    
    // MARK: - 格式化函數
    private func formatAxisAmount(_ amount: Double) -> String {
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""
        if absAmount >= 10000 {
            return String(format: "%@%.0fK", sign, absAmount / 1000)
        } else if absAmount >= 1000 {
            return String(format: "%@%.1fK", sign, absAmount / 1000)
        } else {
            return String(format: "%@%.0f", sign, absAmount)
        }
    }
    
    // MARK: - 資料結構
    struct CategoryChartData: Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
        let color: Color
    }
    
    struct DailyChartData: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }
    
    struct IntervalChartData: Identifiable {
        let id = UUID()
        let period: String
        let amount: Double
        let type: TransactionType // 新增：資料類型（收入/支出/全部）
    }
    
    // MARK: - 消費記錄行
    struct ExpenseRowView: View {
        let expense: ExpenseRecord
        let dataManager: ExpenseDataManager
        
        var body: some View {
            HStack(spacing: 12) {
                // 照片或分類圖標
                if let photoFilename = expense.photoFilename,
                   let image = dataManager.loadImage(for: photoFilename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    let category = dataManager.getCategory(by: expense.categoryId)
                    Circle()
                        .fill(category.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: expense.type == .income ? "plus" : "minus")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.remark)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        let category = dataManager.getCategory(by: expense.categoryId)
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(expense.type == .income ? .green : .red)
                    
                    Text(expense.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ExpenseListView(dataManager: ExpenseDataManager())
}
