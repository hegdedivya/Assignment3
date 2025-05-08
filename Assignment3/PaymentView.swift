//
//  PaymentView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PaymentMethod: Identifiable {
    var id = UUID()
    var name: String
    var icon: String
    var color: Color
}

struct PaymentView: View {
    var friend: Friend
    var amount: Double
    
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var isProcessing = false
    @State private var paymentCompleted = false
    @State private var errorMessage = ""
    @State private var showingConfirmation = false
    @State private var paymentNote = ""
    @State private var showShareOptions = false
    
    @Environment(\.dismiss) private var dismiss
    
    private let paymentMethods = [
        PaymentMethod(name: "Cash", icon: "banknote", color: .green),
        PaymentMethod(name: "Bank Transfer", icon: "arrow.left.arrow.right", color: .blue),
        PaymentMethod(name: "PayPal", icon: "p.circle.fill", color: .blue),
        PaymentMethod(name: "Google Pay", icon: "g.circle.fill", color: .red)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Payment amount
                    VStack(spacing: 8) {
                        Text("Paying")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            // Avatar
                            Circle()
                                .fill(Color.teal.opacity(0.8))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(friend.name.prefix(1).uppercased()))
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                )
                            
                            Text(friend.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Text("$\(String(format: "%.2f", abs(amount)))")
                            .font(.system(size: 48, weight: .bold))
                            .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a note")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g. Dinner payment", text: $paymentNote)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Payment methods
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose payment method")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(paymentMethods) { method in
                                Button(action: {
                                    selectedPaymentMethod = method
                                }) {
                                    HStack {
                                        Image(systemName: method.icon)
                                            .foregroundColor(method.color)
                                            .font(.system(size: 18))
                                        
                                        Text(method.name)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        if selectedPaymentMethod?.id == method.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedPaymentMethod?.id == method.id ? method.color : Color.gray.opacity(0.3),
                                                lineWidth: selectedPaymentMethod?.id == method.id ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    // Payment button
                    Button(action: {
                        if selectedPaymentMethod != nil {
                            showingConfirmation = true
                        } else {
                            errorMessage = "Please select a payment method"
                        }
                    }) {
                        HStack {
                            Text("Confirm Payment")
                            
                            if isProcessing {
                                ProgressView()
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPaymentMethod != nil ? Color.orange : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(selectedPaymentMethod == nil || isProcessing)
                    
                    // Share QR code option
                    Button(action: {
                        showShareOptions = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Payment Info")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Confirm Payment"),
                    message: Text("Are you sure you want to pay $\(String(format: "%.2f", abs(amount))) to \(friend.name)?"),
                    primaryButton: .default(Text("Confirm")) {
                        processPayment()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .sheet(isPresented: $showShareOptions) {
                PaymentShareSheet(friend: friend, amount: amount, note: paymentNote)
            }
            .alert(isPresented: $paymentCompleted) {
                Alert(
                    title: Text("Payment Successful"),
                    message: Text("You have successfully paid $\(String(format: "%.2f", abs(amount))) to \(friend.name)"),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
    
    func processPayment() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in"
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        // Get friend's user ID
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    isProcessing = false
                    errorMessage = "Error processing payment: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    isProcessing = false
                    errorMessage = "User not found"
                    return
                }
                
                // Create a new settlement record
                let settlementData: [String: Any] = [
                    "amount": abs(amount),
                    "from": amount > 0 ? friendID : currentUserID, // If amount is positive, friend owes you
                    "to": amount > 0 ? currentUserID : friendID,   // If amount is positive, payment direction is friend->you
                    "date": Timestamp(),
                    "method": selectedPaymentMethod?.name ?? "Other",
                    "note": paymentNote,
                    "status": "completed"
                ]
                
                db.collection("settlements").addDocument(data: settlementData) { error in
                    if let error = error {
                        isProcessing = false
                        errorMessage = "Error saving settlement record: \(error.localizedDescription)"
                        return
                    }
                    
                    // Update balances
                    updateBalances(friendID: friendID) {
                        DispatchQueue.main.async {
                            isProcessing = false
                            paymentCompleted = true
                        }
                    }
                }
            }
    }
    
    func updateBalances(friendID: String, completion: @escaping () -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in"
            completion()
            return
        }
        
        let db = Firestore.firestore()
        
        // Find balance records between current user and friend
        db.collection("balances")
            .whereField("users", arrayContains: currentUserID)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error updating balances: \(error.localizedDescription)"
                    completion()
                    return
                }
                
                var balanceDocID: String?
                var currentAmounts: [String: Double]?
                
                // Check if there's an existing balance record between these users
                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    if let users = data["users"] as? [String],
                       users.contains(friendID),
                       let amounts = data["amounts"] as? [String: Double] {
                        balanceDocID = doc.documentID
                        currentAmounts = amounts
                        break
                    }
                }
                
                if let balanceDocID = balanceDocID, let currentAmounts = currentAmounts {
                    // Update existing balance
                    var newAmounts = currentAmounts
                    
                    if amount > 0 {
                        // Friend pays you
                        newAmounts[friendID] = (newAmounts[friendID] ?? 0) - abs(amount)
                    } else {
                        // You pay friend
                        newAmounts[currentUserID] = (newAmounts[currentUserID] ?? 0) - abs(amount)
                    }
                    
                    db.collection("balances").document(balanceDocID).updateData([
                        "amounts": newAmounts,
                        "lastUpdated": Timestamp()
                    ]) { error in
                        if let error = error {
                            errorMessage = "Error updating balance: \(error.localizedDescription)"
                        }
                        completion()
                    }
                } else {
                    // Create new balance record
                    let users = [currentUserID, friendID]
                    var amounts = [String: Double]()
                    
                    if amount > 0 {
                        // Friend pays you
                        amounts[friendID] = -abs(amount)
                        amounts[currentUserID] = 0
                    } else {
                        // You pay friend
                        amounts[currentUserID] = -abs(amount)
                        amounts[friendID] = 0
                    }
                    
                    let balanceData: [String: Any] = [
                        "users": users,
                        "amounts": amounts,
                        "created": Timestamp(),
                        "lastUpdated": Timestamp()
                    ]
                    
                    db.collection("balances").addDocument(data: balanceData) { error in
                        if let error = error {
                            errorMessage = "Error creating balance record: \(error.localizedDescription)"
                        }
                        completion()
                    }
                }
            }
    }
}

struct PaymentShareSheet: View {
    var friend: Friend
    var amount: Double
    var note: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Payment Request")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "qrcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    PaymentDetailRow(title: "Amount", value: "$\(String(format: "%.2f", abs(amount)))")
                    PaymentDetailRow(title: "To", value: friend.name)
                    
                    if !note.isEmpty {
                        PaymentDetailRow(title: "Note", value: note)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                HStack(spacing: 15) {
                    ShareButton(title: "Text", icon: "message.fill", color: .green) {
                        // Share via text
                    }
                    
                    ShareButton(title: "Email", icon: "envelope.fill", color: .blue) {
                        // Share via email
                    }
                    
                    ShareButton(title: "Copy", icon: "doc.on.doc", color: .orange) {
                        // Copy payment details
                        UIPasteboard.general.string = "Payment request to \(friend.name) for $\(String(format: "%.2f", abs(amount)))\(note.isEmpty ? "" : " - \(note)")"
                    }
                    
                    ShareButton(title: "More", icon: "square.and.arrow.up", color: .gray) {
                        // Show system share sheet
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct ShareButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct PaymentDetailRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// Create a view to handle adding expenses
struct AddExpenseView: View {
    var friend: Friend
    
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var paidByFriend = false
    @State private var selectedDate = Date()
    @State private var isProcessing = false
    @State private var errorMessage = ""
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
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Add Expense") {
                        addExpense()
                    }
                    .disabled(expenseName.isEmpty || expenseAmount.isEmpty || isProcessing)
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
            errorMessage = "Please enter a valid amount"
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in"
            isProcessing = false
            return
        }
        
        // Get friend's user ID
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    isProcessing = false
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    isProcessing = false
                    errorMessage = "Friend not found"
                    return
                }
                
                // Create new activity for this expense
                let activityData: [String: Any] = [
                    "name": expenseName,
                    "date": Timestamp(date: selectedDate),
                    "members": [currentUserID, friendID],
                    "expenses": [
                        [
                            "itemName": expenseName,
                            "amount": amount,
                            "paidBy": paidByFriend ? friendID : currentUserID,
                            "splitWith": [currentUserID, friendID]
                        ]
                    ],
                    "createdBy": currentUserID,
                    "createdAt": Timestamp()
                ]
                
                db.collection("activities").addDocument(data: activityData) { error in
                    if let error = error {
                        isProcessing = false
                        errorMessage = "Error adding expense: \(error.localizedDescription)"
                        return
                    }
                    
                    // Update balances
                    let perPersonAmount = amount / 2.0
                    
                    // Find balance document
                    db.collection("balances")
                        .whereField("users", arrayContains: currentUserID)
                        .getDocuments { balanceSnapshot, balanceError in
                            if let balanceError = balanceError {
                                isProcessing = false
                                errorMessage = "Error updating balances: \(balanceError.localizedDescription)"
                                return
                            }
                            
                            var balanceDocID: String?
                            var currentAmounts: [String: Double]?
                            
                            // Check if there's an existing balance record
                            for doc in balanceSnapshot?.documents ?? [] {
                                let data = doc.data()
                                if let users = data["users"] as? [String],
                                   users.contains(friendID),
                                   let amounts = data["amounts"] as? [String: Double] {
                                    balanceDocID = doc.documentID
                                    currentAmounts = amounts
                                    break
                                }
                            }
                            
                            if let balanceDocID = balanceDocID, var amounts = currentAmounts {
                                // Update existing balance
                                if paidByFriend {
                                    // Friend paid, you owe them
                                    amounts[currentUserID] = (amounts[currentUserID] ?? 0) + perPersonAmount
                                } else {
                                    // You paid, they owe you
                                    amounts[friendID] = (amounts[friendID] ?? 0) + perPersonAmount
                                }
                                
                                db.collection("balances").document(balanceDocID).updateData([
                                    "amounts": amounts,
                                    "lastUpdated": Timestamp()
                                ]) { error in
                                    isProcessing = false
                                    
                                    if let error = error {
                                        errorMessage = "Error updating balance: \(error.localizedDescription)"
                                    } else {
                                        expenseAdded = true
                                    }
                                }
                            } else {
                                // Create new balance
                                let users = [currentUserID, friendID]
                                var amounts = [String: Double]()
                                
                                if paidByFriend {
                                    // Friend paid, you owe them
                                    amounts[currentUserID] = perPersonAmount
                                    amounts[friendID] = 0
                                } else {
                                    // You paid, they owe you
                                    amounts[friendID] = perPersonAmount
                                    amounts[currentUserID] = 0
                                }
                                
                                let balanceData: [String: Any] = [
                                    "users": users,
                                    "amounts": amounts,
                                    "created": Timestamp(),
                                    "lastUpdated": Timestamp()
                                ]
                                
                                db.collection("balances").addDocument(data: balanceData) { error in
                                    isProcessing = false
                                    
                                    if let error = error {
                                        errorMessage = "Error creating balance: \(error.localizedDescription)"
                                    } else {
                                        expenseAdded = true
                                    }
                                }
                            }
                        }
                }
            }
    }
}

#Preview {
    PaymentView(friend: Friend(name: "John Doe", email: "john@example.com", amountOwed: 25.50), amount: 25.50)
}
