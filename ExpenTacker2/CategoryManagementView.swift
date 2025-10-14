//
//  CategoryManagementView.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/1.
//

import SwiftUI

struct CategoryManagementView: View {
    let dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false
    @State private var editingCategory: ExpenseCategory? = nil
    
    private var noneCategory: ExpenseCategory { ExpenseCategory.noneCategory }
    private var incomeCategories: [ExpenseCategory] {
        dataManager.categories.filter { $0.type == .income && !$0.isDefault }
    }
    private var expenseCategories: [ExpenseCategory] {
        dataManager.categories.filter { $0.type == .expense && !$0.isDefault }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("預設") {
                    CategoryRowView(category: noneCategory)
                        .opacity(0.7)
                        // 預設不可編輯/刪除
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) { }
                }
                
                Section("收入分類") {
                    if incomeCategories.isEmpty {
                        Text("尚未建立收入分類").foregroundColor(.secondary)
                    }
                    ForEach(incomeCategories) { category in
                        CategoryRowView(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture { editingCategory = category }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button { editingCategory = category } label: {
                                    Label("編輯", systemImage: "pencil")
                                }.tint(.blue)
                                Button(role: .destructive) { dataManager.deleteCategory(category) } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteIncome)
                }
                
                Section("支出分類") {
                    if expenseCategories.isEmpty {
                        Text("尚未建立支出分類").foregroundColor(.secondary)
                    }
                    ForEach(expenseCategories) { category in
                        CategoryRowView(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture { editingCategory = category }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button { editingCategory = category } label: {
                                    Label("編輯", systemImage: "pencil")
                                }.tint(.blue)
                                Button(role: .destructive) { dataManager.deleteCategory(category) } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteExpense)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("分類管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddCategory = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(dataManager: dataManager)
            }
            .sheet(item: $editingCategory, content: { category in
                EditCategoryView(dataManager: dataManager, category: category)
            })
        }
    }
    
    private func deleteIncome(at offsets: IndexSet) {
        let items = incomeCategories
        offsets.map { items[$0] }.forEach { dataManager.deleteCategory($0) }
    }
    
    private func deleteExpense(at offsets: IndexSet) {
        let items = expenseCategories
        offsets.map { items[$0] }.forEach { dataManager.deleteCategory($0) }
    }
}

struct CategoryRowView: View {
    let category: ExpenseCategory
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(category.color)
                .frame(width: 18, height: 18)
            
            Text(category.name)
                .font(.subheadline)
            
            Spacer()
            
            Text(category.type.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.type == .income ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .foregroundColor(category.type == .income ? .green : .red)
                .cornerRadius(8)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    CategoryManagementView(dataManager: ExpenseDataManager())
}
