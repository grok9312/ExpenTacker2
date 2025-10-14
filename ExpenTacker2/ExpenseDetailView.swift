import SwiftUI

struct ExpenseDetailView: View {
    @ObservedObject var dataManager: ExpenseDataManager
    let expense: ExpenseRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 24) {
            // 金額與類型
            HStack(spacing: 16) {
                Circle()
                    .fill(category.color)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: expense.type == .income ? "plus" : "minus")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.remark)
                        .font(.title2.bold())
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(expense.formattedAmount)
                    .font(.title2.bold())
                    .foregroundColor(expense.type == .income ? .green : .red)
            }
            .padding(.top)

            // 其他資訊
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("日期")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(expense.formattedDate)
                }
                HStack {
                    Text("分類")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(category.name)
                }
                if !expense.remark.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("備註")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(expense.remark)
                    }
                }
                if let photoFilename = expense.photoFilename,
                   let image = dataManager.loadImage(for: photoFilename) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("照片")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGroupedBackground)))

            Spacer()
        }
        .padding()
        .navigationTitle("明細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Label("編輯", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("刪除", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditExpenseView(dataManager: dataManager, expense: expense)
        }
        .alert("確定要刪除這筆記錄嗎？", isPresented: $showingDeleteAlert, actions: {
            Button("刪除", role: .destructive) {
                dataManager.deleteExpense(expense)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        })
    }

    private var category: ExpenseCategory {
        dataManager.getCategory(by: expense.categoryId)
    }
}

#Preview {
    let manager = ExpenseDataManager()
    let expense = manager.expenses.first ?? ExpenseRecord(
        remark: "午餐",
        amount: 100,
        date: Date(),
        type: .expense,
        color: .blue,
        categoryId: manager.categories.first?.id,
        photoFilename: nil
    )
    NavigationView {
        ExpenseDetailView(dataManager: manager, expense: expense)
    }
}
