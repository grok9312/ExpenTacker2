//
//  AddCategoryView.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/1.
//

import SwiftUI

struct AddCategoryView: View {
    let dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedColor: Color = .blue
    
    var body: some View {
        NavigationView {
            Form {
                Section("分類資訊") {
                    // 分類名稱輸入
                    HStack {
                        Text("名稱")
                        TextField("請輸入分類名稱", text: $categoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 類型選擇
                    HStack {
                        Text("類型")
                        Spacer()
                        Picker("類型", selection: $selectedType) {
                            Text("收入").tag(TransactionType.income)
                            Text("支出").tag(TransactionType.expense)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }
                }
                
                // 使用系統顏色挑選器
                Section("顏色選擇") {
                    ColorPicker("顏色", selection: $selectedColor, supportsOpacity: true)
                }
                
                Section("預覽") {
                    previewSection
                }
            }
            .navigationTitle("新增分類")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
    
    private var previewSection: some View {
        HStack {
            Circle()
                .fill(selectedColor)
                .frame(width: 30, height: 30)
            
            Text(categoryName.isEmpty ? "分類名稱" : categoryName)
                .font(.subheadline)
                .foregroundColor(categoryName.isEmpty ? .secondary : .primary)
            
            Spacer()
            
            Text(selectedType.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedType == .income ? .green.opacity(0.2) : .red.opacity(0.2))
                .foregroundColor(selectedType == .income ? .green : .red)
                .cornerRadius(8)
        }
        .padding(.vertical, 5)
    }
    
    private func saveCategory() {
        let newCategory = ExpenseCategory(
            name: categoryName,
            color: selectedColor,
            type: selectedType
        )
        
        dataManager.addCategory(newCategory)
        dismiss()
    }
}

#Preview {
    AddCategoryView(dataManager: ExpenseDataManager())
}
