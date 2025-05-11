//
//  AddExpenseView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    var group: Group
    
    @State private var expenseName: String = ""
    @State private var expenseAmount: String = ""
    @State private var paidByUser: String = ""
    @State private var selectedDate = Date()
    @State private var splitEqually = true
    @State private var customSplits: [String: Double] = [:]
    @State private var showingMembersPicker = false
    @State private var selectedMembers: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    @State private var memberNames: [String: String] = [:]
    
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    // Calculate per person amount for equal splits
    var perPersonAmount: Double {
        guard let amount = Double(expenseAmount), amount > 0 else { return 0 }
        let memberCount = selectedMembers.isEmpty ? group.members.count : selectedMembers.count
        return amount / Double(memberCount)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Expense Details Section
                Section(header: Text("Expense Details")) {
                    TextField("Expense name", text: $expenseName)
                        .autocapitalization(.words)
                    
                    HStack {
                        Text("$")
                        TextField("Amount", text: $expenseAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                // Payment Section
                Section(header: Text("Payment")) {
                    Picker("Paid by", selection: $paidByUser) {
                        ForEach(group.members, id: \.self) { memberID in
                            Text(getMemberName(memberID))
                                .tag(memberID)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onAppear {
                        // Set default payer to current user
                        if paidByUser.isEmpty {
                            paidByUser = dataManager.getCurrentUserID() ?? ""
                        }
                    }
                }
                
                // Split Section
                Section(header: Text("Split Options")) {
                    Toggle("Split equally", isOn: $splitEqually)
                    
                    if splitEqually {
                        HStack {
                            Text("Each person pays")
                            Spacer()
                            Text("$\(String(format: "%.2f", perPersonAmount))")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button(action: {
                            showingMembersPicker = true
                        }) {
                            HStack {
                                Text("Select members to split with")
                                Spacer()
                                Text("\(selectedMembers.count) selected")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        ForEach(selectedMembers, id: \.self) { memberID in
                            HStack {
                                Text(getMemberName(memberID))
                                Spacer()
                                TextField("$", text: Binding(
                                    get: { String(format: "%.2f", customSplits[memberID] ?? 0) },
                                    set: { newValue in
                                        if let amount = Double(newValue) {
                                            customSplits[memberID] = amount
                                        }
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            }
                        }
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                // Add Expense Button
                Section {
                    Button(action: addExpense) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Add Expense")
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .disabled(expenseName.isEmpty || expenseAmount.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showingMembersPicker) {
                MemberPickerView(
                    group: group,
                    selectedMembers: $selectedMembers,
                    customSplits: $customSplits,
                    memberNames: memberNames
                )
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Expense Added"),
                    message: Text("Your expense has been added successfully."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
            .onAppear {
                loadMemberNames()
            }
        }
    }
    
    // Load member names
    func loadMemberNames() {
        let db = Firestore.firestore()
        
        for memberID in group.members {
            // Skip if it's the current user
            if memberID == dataManager.getCurrentUserID() {
                memberNames[memberID] = "You"
                continue
            }
            
            // Skip if we already have the name
            if memberNames[memberID] != nil {
                continue
            }
            
            db.collection("users").document(memberID).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching member: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    let firstName = data["firstName"] as? String ?? ""
                    let lastName = data["lastName"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        if !firstName.isEmpty || !lastName.isEmpty {
                            self.memberNames[memberID] = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            self.memberNames[memberID] = "Member \(memberID.prefix(4))"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.memberNames[memberID] = "Member \(memberID.prefix(4))"
                    }
                }
            }
        }
    }
    
    // Get member name from ID
    func getMemberName(_ memberID: String) -> String {
        if let name = memberNames[memberID] {
            return name
        }
        
        if memberID == dataManager.getCurrentUserID() {
            return "You"
        }
        
        // Fallback to member ID
        return "Member \(memberID.prefix(4))"
    }
    
    // Add expense to Firebase
    func addExpense() {
        guard !expenseName.isEmpty else {
            errorMessage = "Please enter an expense name"
            return
        }
        
        guard let amount = Double(expenseAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard !paidByUser.isEmpty else {
            errorMessage = "Please select who paid"
            return
        }
        
        guard let groupID = group.id else {
            errorMessage = "Invalid group ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Determine members to split with
        let splitMembers = splitEqually ? group.members : selectedMembers
        if splitMembers.isEmpty {
            isLoading = false
            errorMessage = "Please select at least one person to split with"
            return
        }
        
        // Create expense data
        let expenseID = UUID().uuidString
        let membersToSplitWith = splitMembers
        
        // Calculate amounts
        var splitAmounts: [String: Double] = [:]
        
        if splitEqually {
            // Equal split
            let perMemberAmount = amount / Double(membersToSplitWith.count)
            for memberID in membersToSplitWith {
                splitAmounts[memberID] = perMemberAmount
            }
        } else {
            // Custom split
            splitAmounts = customSplits
            
            // Verify total matches
            let totalSplit = splitAmounts.values.reduce(0, +)
            if abs(totalSplit - amount) > 0.01 {
                isLoading = false
                errorMessage = "Split amounts must equal the total expense"
                return
            }
        }
        
        // Create expense structure
        let expenseData: [String: Any] = [
            "name": expenseName,
            "amount": amount,
            "date": Timestamp(date: selectedDate),
            "paidBy": paidByUser,
            "splitAmounts": splitAmounts,
            "groupID": groupID,
            "createdAt": Timestamp(),
            "createdBy": dataManager.getCurrentUserID() ?? ""
        ]
        
        // Add to Firestore under the group's expenses collection
        let db = Firestore.firestore()
        db.collection("Group").document(groupID).collection("expenses").document(expenseID).setData(expenseData) { error in
            if let error = error {
                isLoading = false
                errorMessage = "Error adding expense: \(error.localizedDescription)"
                return
            }
            
            // Also add to the main expenses collection for global queries
            db.collection("Expenses").document(expenseID).setData(expenseData) { error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error adding to expenses collection: \(error.localizedDescription)"
                    return
                }
                
                // Update balances between members
                self.updateBalances(
                    groupID: groupID,
                    paidByUserID: self.paidByUser,
                    splitAmounts: splitAmounts
                ) { success in
                    if success {
                        showSuccessAlert = true
                    } else {
                        errorMessage = "Error updating balances"
                    }
                }
            }
        }
    }
    
    // Update balances between members - FIXED VERSION
    func updateBalances(groupID: String, paidByUserID: String, splitAmounts: [String: Double], completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // Track completed operations
        var pendingOperations = 0
        var successfulOperations = 0
        var failedOperations = 0
        
        // For each member who's part of the split
        for (memberID, amount) in splitAmounts {
            // Skip if this is the payer (they don't owe themselves)
            if memberID == paidByUserID {
                continue
            }
            
            pendingOperations += 1
            
            // Look for existing balance document between these two users
            let balanceQuery = db.collection("balances")
                .whereField("users", arrayContains: paidByUserID)
                .getDocuments { snapshot, error in
                    defer {
                        // Check if all operations are complete
                        if pendingOperations == (successfulOperations + failedOperations) {
                            completion(failedOperations == 0)
                        }
                    }
                    
                    if let error = error {
                        print("Error querying balances: \(error)")
                        failedOperations += 1
                        return
                    }
                    
                    // Find a balance doc that contains both users
                    var existingBalanceDoc: QueryDocumentSnapshot?
                    for doc in snapshot?.documents ?? [] {
                        if let users = doc.data()["users"] as? [String],
                           users.contains(memberID) {
                            existingBalanceDoc = doc
                            break
                        }
                    }
                    
                    if let existingBalanceDoc = existingBalanceDoc {
                        // Update existing balance
                        let balanceRef = db.collection("balances").document(existingBalanceDoc.documentID)
                        var amounts = existingBalanceDoc.data()["amounts"] as? [String: Double] ?? [:]
                        
                        // Member owes payer
                        if let currentAmount = amounts[memberID] {
                            amounts[memberID] = currentAmount + amount
                        } else {
                            amounts[memberID] = amount
                        }
                        
                        balanceRef.updateData([
                            "amounts": amounts,
                            "lastUpdated": Timestamp()
                        ]) { error in
                            if let error = error {
                                print("Error updating balance: \(error)")
                                failedOperations += 1
                            } else {
                                successfulOperations += 1
                            }
                        }
                    } else {
                        // Create new balance document
                        let balanceRef = db.collection("balances").document()
                        let balanceData: [String: Any] = [
                            "users": [paidByUserID, memberID],
                            "amounts": [memberID: amount],
                            "groupID": groupID,
                            "created": Timestamp(),
                            "lastUpdated": Timestamp()
                        ]
                        
                        balanceRef.setData(balanceData) { error in
                            if let error = error {
                                print("Error creating balance: \(error)")
                                failedOperations += 1
                            } else {
                                successfulOperations += 1
                            }
                        }
                    }
                }
        }
        
        // If no pending operations (e.g., no splitAmounts entries), call completion right away
        if pendingOperations == 0 {
            completion(true)
        }
    }
}

// Helper view for selecting members to split with
struct MemberPickerView: View {
    @Environment(\.dismiss) var dismiss
    var group: Group
    @Binding var selectedMembers: [String]
    @Binding var customSplits: [String: Double]
    var memberNames: [String: String]
    
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(group.members, id: \.self) { memberID in
                    Button(action: {
                        toggleMember(memberID)
                    }) {
                        HStack {
                            Text(getMemberName(memberID))
                            
                            Spacer()
                            
                            if selectedMembers.contains(memberID) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Members")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Done") {
                    // Initialize custom splits for selected members
                    for memberID in selectedMembers {
                        if customSplits[memberID] == nil {
                            customSplits[memberID] = 0
                        }
                    }
                    dismiss()
                }
            )
        }
    }
    
    // Toggle member selection
    func toggleMember(_ memberID: String) {
        if selectedMembers.contains(memberID) {
            selectedMembers.removeAll { $0 == memberID }
            customSplits.removeValue(forKey: memberID)
        } else {
            selectedMembers.append(memberID)
            customSplits[memberID] = 0
        }
    }
    
    // Get member name from ID
    func getMemberName(_ memberID: String) -> String {
        if let name = memberNames[memberID] {
            return name
        }
        
        if memberID == dataManager.getCurrentUserID() {
            return "You"
        }
        
        // Fallback to member ID
        return "Member \(memberID.prefix(4))"
    }
}
