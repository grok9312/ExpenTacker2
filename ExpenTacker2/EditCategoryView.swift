//
//  EditCategoryView.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/2.
//

import SwiftUI

struct EditCategoryView: View {
    let dataManager: ExpenseDataManager
    let category: ExpenseCategory
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var type: TransactionType
    @State private var color: Color
    
    init(dataManager: ExpenseDataManager, category: ExpenseCategory) {
        self.dataManager = dataManager
        self.category = category
        _name = State(initialValue: category.name)
        _type = State(initialValue: category.type == .all ? .expense : category.type)
        _color = State(initialValue: category.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("分類資訊") {
                    HStack {
                        Text("名稱")
                        TextField("請輸入分類名稱", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("類型")
                        Spacer()
                        Picker("類型", selection: $type) {
                            Text("收入").tag(TransactionType.income)
                            Text("支出").tag(TransactionType.expense)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                        .disabled(category.isDefault) // 預設none不可改
                    }
                }
                
                Section("顏色選擇") {
                    ColorPicker("顏色", selection: $color, supportsOpacity: true)
                        .disabled(category.isDefault) // 預設none不可改
                }
                
                Section("預覽") {
                    HStack {
                        Circle().fill(color).frame(width: 30, height: 30)
                        Text(name.isEmpty ? "分類名稱" : name)
                            .font(.subheadline)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                        Spacer()
                        Text((category.isDefault ? category.type : type).displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((category.isDefault ? category.type : type) == .income ? .green.opacity(0.2) : .red.opacity(0.2))
                            .foregroundColor((category.isDefault ? category.type : type) == .income ? .green : .red)
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("編輯分類")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        var updated = category
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !category.isDefault { // 預設none不允許改型別/顏色
            updated.type = type
            updated.color = color
        }
        dataManager.updateCategory(updated)
        dismiss()
    }
}

#Preview {
    EditCategoryView(dataManager: ExpenseDataManager(), category: ExpenseCategory(name: "餐飲", color: .red, type: .expense))
}
