//
//  AddExpenseView.swift
//  ExpenTacker2
//
//  Created by 張郁眉 on 2025/10/1.
//

import SwiftUI
import PhotosUI

struct AddExpenseView: View {
    let dataManager: ExpenseDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var remark = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedDate = Date()
    @State private var selectedCategoryId: String? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section("交易資訊") {
                    // 交易類型選擇
                    HStack {
                        Text("類型")
                        Spacer()
                        Picker("類型", selection: $selectedType) {
                            Text("收入").tag(TransactionType.income)
                            Text("支出").tag(TransactionType.expense)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                        .onChange(of: selectedType) { _, _ in
                            selectedCategoryId = nil
                        }
                    }
                    
                    // 金額輸入
                    HStack {
                        Text("金額")
                        TextField("請輸入金額", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 備註輸入
                    HStack {
                        Text("備註")
                        TextField("請輸入備註", text: $remark)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 日期選擇
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section("分類選擇") {
                    // 以下拉選單選擇分類（含無分類）
                    let availableCategories = dataManager.getCategories(for: selectedType)
                        .filter { !$0.isDefault } // 避免與「無分類」重複
                    
                    Picker("分類", selection: $selectedCategoryId) {
                        // 無分類
                        HStack {
                            Circle().fill(Color.gray).frame(width: 12, height: 12)
                            Text("無分類")
                        }
                        .tag(String?.none)
                        
                        // 其他分類
                        ForEach(availableCategories) { category in
                            HStack {
                                Circle().fill(category.color).frame(width: 12, height: 12)
                                Text(category.name)
                            }
                            .tag(Optional(category.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("照片（可選）") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                            Text(selectedPhotoData == nil ? "選擇照片" : "已選擇照片")
                                .foregroundColor(selectedPhotoData == nil ? .blue : .green)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                    
                    if let photoData = selectedPhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        Button(role: .destructive) {
                            selectedPhotoData = nil
                            selectedPhotoItem = nil
                        } label: {
                            Label("移除照片", systemImage: "trash")
                        }
                    }
                }
                
                Section("預覽") {
                    previewSection
                }
            }
            .navigationTitle("新增記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveExpense()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private var previewSection: some View {
        HStack {
            let category = dataManager.getCategory(by: selectedCategoryId)
            
            Circle()
                .fill(category.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: selectedType == .income ? "plus" : "minus")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(remark.isEmpty ? "備註內容" : remark)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(remark.isEmpty ? .secondary : .primary)
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatPreviewAmount())
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(selectedType == .income ? .green : .red)
                
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formatPreviewAmount() -> String {
        guard let amountValue = Double(amount) else {
            return selectedType == .expense ? "-NT$0" : "+NT$0"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TWD"
        formatter.maximumFractionDigits = 0
        
        let prefix = selectedType == .expense ? "-" : "+"
        let formattedNumber = formatter.string(from: NSNumber(value: amountValue)) ?? "NT$0"
        
        return prefix + formattedNumber
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let category = dataManager.getCategory(by: selectedCategoryId)
        
        // 儲存照片（如果有選擇）
        var photoFilename: String? = nil
        if let photoData = selectedPhotoData {
            photoFilename = dataManager.saveImageData(photoData)
        }
        
        let newExpense = ExpenseRecord(
            remark: remark.isEmpty ? "無備註" : remark,
            amount: amountValue,
            date: selectedDate,
            type: selectedType,
            color: category.color,
            categoryId: selectedCategoryId,
            photoFilename: photoFilename
        )
        
        dataManager.addExpense(newExpense)
        dismiss()
    }
}

#Preview {
    AddExpenseView(dataManager: ExpenseDataManager())
}
