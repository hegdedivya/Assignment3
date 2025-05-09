//
//  AddExpenseView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct AddExpenseView: View {
    var friend: Friend
    
    @StateObject private var viewModel = PaymentViewModel()
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var paidByFriend = false
    @State private var selectedDate = Date()
    @State private var expenseAdded = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Expense name", text: $expenseName)
                    
                    TextField("Amount", text: $expenseAmount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    Toggle("Paid by \(friend.name)", isOn: $paidByFriend)
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Section {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Add Expense") {
                        addExpense()
                    }
                    .disabled(expenseName.isEmpty || expenseAmount.isEmpty || viewModel.isProcessing)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert(isPresented: $expenseAdded) {
                Alert(
                    title: Text("Expense Added"),
                    message: Text("The expense has been successfully added."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func addExpense() {
        guard let amount = Double(expenseAmount) else {
            viewModel.errorMessage = "Please enter a valid amount"
            return
        }
        
        viewModel.addExpense(
            name: expenseName,
            amount: amount,
            date: selectedDate,
            friend: friend,
            paidByFriend: paidByFriend
        ) { success, errorMessage in
            if success {
                expenseAdded = true
            } else if let errorMessage = errorMessage {
                viewModel.errorMessage = errorMessage
            }
        }
    }
}

struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView(friend: Friend(id: "1", name: "John Doe", email: "john@example.com"))
    }
}
