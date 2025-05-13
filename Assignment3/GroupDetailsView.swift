//
//  GroupDetailsView.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//
 
import SwiftUI
import FirebaseFirestore
 
struct GroupDetailView: View {
    var group: Group
    @State private var isAddUserPresented: Bool = false
    @State private var isAddExpensePresented: Bool = false
    @State private var groupMembers: [UserProfile] = []
    @State private var groupExpenses: [DetailedExpense] = []
    @State private var isLoadingMembers = false
    @State private var isLoadingExpenses = false
    @State private var errorMessage: String?
    @State private var selectedMonth: Date = Date()
    @State private var selectedTab: Int = 0
    @State private var totalBalances: [String: Double] = [:]
    @State private var showingSettleUpSheet = false
    
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Group Header
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: getGroupIcon(type: group.type ?? "Other"))
                        .font(.system(size: 30))
                        .foregroundColor(.teal)
                }
                .padding(.top)
                
                Text(group.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(group.members.count) members")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Created \(group.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Balance Summary
                if let currentUserID = dataManager.getCurrentUserID() {
                    let userDebts = getUserDebts(for: currentUserID)
                    if !userDebts.isEmpty {
                        VStack(spacing: 2) {
                            ForEach(userDebts, id: \.personID) { debt in
                                if debt.amount > 0 {
                                    Text("You owe \(memberNames[debt.personID] ?? "someone") \(formatCurrency(debt.amount))")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                } else if debt.amount < 0 {
                                    Text("\(memberNames[debt.personID] ?? "Someone") owes you \(formatCurrency(abs(debt.amount)))")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Action Buttons
            HStack(spacing: 20) {
                Spacer()
                
                Button(action: {
                    isAddExpensePresented = true
                }) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                            )
                        
                        Text("Add Expense")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    isAddUserPresented = true
                }) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.white)
                            )
                        
                        Text("Add User")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingSettleUpSheet = true
                }) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "creditcard")
                                    .foregroundColor(.white)
                            )
                        
                        Text("Settle Up")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            
            // Month selector (only show in expenses tab)
            if selectedTab == 0 {
                HStack {
                    Button(action: {
                        // Go to previous month
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(monthYearFormatter.string(from: selectedMonth))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        // Go to next month
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            // Content based on selected tab
            if selectedTab == 0 {
                // Expenses List
                if isLoadingExpenses {
                    Spacer()
                    ProgressView("Loading expenses...")
                    Spacer()
                } else if filteredExpenses.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding()
                        
                        Text("No expenses for this month")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredExpenses) { expense in
                                ExpenseRowView(
                                    expense: expense,
                                    currentUserID: dataManager.getCurrentUserID() ?? "",
                                    memberNames: memberNames
                                )
                                
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            } else if selectedTab == 1 {
                // Members Tab
                if isLoadingMembers {
                    Spacer()
                    ProgressView("Loading members...")
                    Spacer()
                } else if groupMembers.isEmpty {
                    Spacer()
                    Text("No members found")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(groupMembers) { member in
                                MemberRowView(
                                    member: member,
                                    isCurrentUser: member.id == dataManager.getCurrentUserID(),
                                    balance: totalBalances[member.id] ?? 0,
                                    currentUserID: dataManager.getCurrentUserID() ?? ""
                                )
                                
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            } else if selectedTab == 2 {
                // Activities Tab
                Spacer()
                Text("Activities")
                    .font(.headline)
                Spacer()
            } else {
                // Balances Tab
                BalancesSummaryView(
                    members: groupMembers,
                    totalBalances: totalBalances,
                    currentUserID: dataManager.getCurrentUserID() ?? "",
                    group: group
                )
            }
            
            Spacer()
            
            // Custom Tab Bar
            HStack {
                TabButton(
                    imageName: "list.bullet",
                    text: "Expenses",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabButton(
                    imageName: "person.3",
                    text: "Members",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                TabButton(
                    imageName: "doc.richtext",
                    text: "Activities",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
                
                TabButton(
                    imageName: "dollarsign.circle",
                    text: "Balances",
                    isSelected: selectedTab == 3
                ) {
                    selectedTab = 3
                }
            }
            .padding(.vertical, 8)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -1)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(group.name)
                    .font(.headline)
            }
        }
        .onAppear {
            loadGroupMembers()
            loadGroupExpenses()
        }
        .sheet(isPresented: $isAddUserPresented) {
            AddUserToGroupView(group: group, onUserAdded: {
                loadGroupMembers()
            })
        }
        .sheet(isPresented: $isAddExpensePresented) {
            AddExpenseView(group: group)
        }
        .sheet(isPresented: $showingSettleUpSheet) {
            GroupSettleUpView(group: group, totalBalances: totalBalances)
        }
        .onChange(of: isAddExpensePresented) { isPresented in
            if !isPresented {
                // Refresh expenses when modal is dismissed
                loadGroupExpenses()
            }
        }
    }
    
    // Dictionary of member names for easier lookup
    var memberNames: [String: String] {
        var names: [String: String] = [:]
        for member in groupMembers {
            if member.id == dataManager.getCurrentUserID() {
                names[member.id] = "You"
            } else {
                names[member.id] = member.fullName
            }
        }
        return names
    }
    
    // Format currency
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // Calculate how much the current user owes to each person
    func getUserDebts(for userID: String) -> [UserDebt] {
        var debts: [String: Double] = [:]
        
        // Calculate each expense's contribution to debt
        for expense in groupExpenses {
            if let paidBy = expense.paidBy {
                if paidBy == userID {
                    // Current user paid, others owe them
                    for (memberID, amount) in expense.splitAmounts where memberID != userID {
                        debts[memberID] = (debts[memberID] ?? 0) - amount // Negative means they owe user
                    }
                } else if expense.splitAmounts[userID] != nil {
                    // Current user owes the payer
                    debts[paidBy] = (debts[paidBy] ?? 0) + (expense.splitAmounts[userID] ?? 0)
                }
            }
        }
        
        // Convert to array of UserDebt
        var userDebts: [UserDebt] = []
        for (personID, amount) in debts {
            if abs(amount) > 0.01 { // Only include non-zero debts
                userDebts.append(UserDebt(personID: personID, amount: amount))
            }
        }
        
        // Update total balances for use elsewhere
        DispatchQueue.main.async {
            self.totalBalances = debts
        }
        
        return userDebts.sorted { abs($0.amount) > abs($1.amount) } // Sort by amount (largest first)
    }
    
    // Filter expenses by selected month
    var filteredExpenses: [DetailedExpense] {
        groupExpenses.filter { expense in
            guard let date = expense.date else { return false }
            return isInSameMonth(date1: date, date2: selectedMonth)
        }
        .sorted { (exp1, exp2) -> Bool in
            guard let date1 = exp1.date, let date2 = exp2.date else {
                return false
            }
            return date1 > date2 // Sort by most recent first
        }
    }
    
    // Check if two dates are in the same month and year
    func isInSameMonth(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month], from: date1)
        let components2 = calendar.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }
    
    // Date formatter for month and year
    var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    // Helper function to get an icon for group type
    func getGroupIcon(type: String) -> String {
        switch type.lowercased() {
        case "trip": return "airplane"
        case "home": return "house"
        case "couple": return "heart"
        default: return "list.bullet"
        }
    }
    
    // Load group member details
    func loadGroupMembers() {
        isLoadingMembers = true
        groupMembers = []
        errorMessage = nil
        
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        
        for memberID in group.members {
            dispatchGroup.enter()
            
            db.collection("users").document(memberID).getDocument { snapshot, error in
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    print("Error loading member data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                let firstName = data["firstName"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                let member = UserProfile(
                    id: memberID,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    phoneNumber: data["phoneNumber"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    self.groupMembers.append(member)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoadingMembers = false
            
            // Calculate balances after members are loaded
            if let userID = self.dataManager.getCurrentUserID() {
                _ = self.getUserDebts(for: userID)
            }
        }
    }
    
    // Load group expenses with real-time listener
    func loadGroupExpenses() {
        guard let groupID = group.id else { return }
        
        isLoadingExpenses = true
        groupExpenses = []
        
        let db = Firestore.firestore()
        
        db.collection("Group").document(groupID).collection("expenses")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingExpenses = false
                    
                    if let error = error {
                        print("Error loading expenses: \(error.localizedDescription)")
                        return
                    }
                    
                    var expenses: [DetailedExpense] = []
                    
                    for document in snapshot?.documents ?? [] {
                        let data = document.data()
                        
                        guard let itemName = data["name"] as? String,
                              let amount = data["amount"] as? Double else {
                            continue
                        }
                        
                        var expense = DetailedExpense(
                            id: document.documentID,
                            itemName: itemName,
                            amount: amount
                        )
                        
                        // Add additional information
                        if let dateTimestamp = data["date"] as? Timestamp {
                            expense.date = dateTimestamp.dateValue()
                        }
                        
                        if let paidBy = data["paidBy"] as? String {
                            expense.paidBy = paidBy
                        }
                        
                        if let splitAmounts = data["splitAmounts"] as? [String: Double] {
                            expense.splitAmounts = splitAmounts
                        }
                        
                        expenses.append(expense)
                    }
                    
                    self.groupExpenses = expenses
                    
                    // Recalculate balances when expenses change
                    if let userID = self.dataManager.getCurrentUserID() {
                        _ = self.getUserDebts(for: userID)
                    }
                }
            }
    }
}
 
// User debt model
struct UserDebt {
    let personID: String
    let amount: Double
}
 
// Tab Button Component
struct TabButton: View {
    let imageName: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: imageName)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
 
// Detailed expense model
struct DetailedExpense: Identifiable {
    var id: String
    var itemName: String
    var amount: Double
    var date: Date?
    var paidBy: String?
    var splitAmounts: [String: Double] = [:]
    
    // Calculate how much the current user owes for this expense
    func calculateUserBalance(for userID: String) -> Double {
        // If user paid for this expense
        if paidBy == userID {
            // Find how much others owe the user
            var totalOwed: Double = 0
            for (memberID, splitAmount) in splitAmounts {
                if memberID != userID {
                    totalOwed += splitAmount
                }
            }
            return totalOwed
        } else {
            // User owes the amount they are responsible for
            return -(splitAmounts[userID] ?? 0)
        }
    }
}
 
// Expense row view component - updated to match screenshot
struct ExpenseRowView: View {
    let expense: DetailedExpense
    let currentUserID: String
    let memberNames: [String: String]
    
    var body: some View {
        HStack(spacing: 16) {
            // Left column - Date
            VStack(alignment: .center) {
                if let date = expense.date {
                    Text(monthFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(dayFormatter.string(from: date))
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 40)
            
            // Icon
            Image(systemName: "doc.text")
                .font(.system(size: 22))
                .foregroundColor(.gray)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            
            // Middle column - Expense details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.itemName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let paidBy = expense.paidBy {
                    if paidBy == currentUserID {
                        Text("You paid $\(String(format: "%.2f", expense.amount))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else if let payerName = memberNames[paidBy] {
                        Text("\(payerName) paid $\(String(format: "%.2f", expense.amount))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Right column - Balance
            VStack(alignment: .trailing, spacing: 2) {
                let balance = expense.calculateUserBalance(for: currentUserID)
                if balance > 0 {
                    Text("you lent")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("$\(String(format: "%.2f", balance))")
                        .font(.headline)
                        .foregroundColor(.green)
                } else if balance < 0 {
                    Text("you borrowed")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("$\(String(format: "%.2f", abs(balance)))")
                        .font(.headline)
                        .foregroundColor(.orange)
                } else {
                    Text("not involved")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
    
    // Date formatters
    var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }
}
 
// Member row view component
struct MemberRowView: View {
    let member: UserProfile
    let isCurrentUser: Bool
    let balance: Double
    let currentUserID: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Member avatar
            Circle()
                .fill(Color.teal.opacity(0.8))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(member.fullName.prefix(1)))
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                )
            
            // Member info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isCurrentUser ? "You" : member.fullName)
                        .font(.headline)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.teal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.teal, lineWidth: 1)
                            )
                    }
                }
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Balance info
            if !isCurrentUser {
                VStack(alignment: .trailing, spacing: 2) {
                    if balance > 0 {
                        Text("owes you")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("$\(String(format: "%.2f", balance))")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else if balance < 0 {
                        Text("you owe")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("$\(String(format: "%.2f", abs(balance)))")
                            .font(.headline)
                            .foregroundColor(.orange)
                    } else {
                        Text("settled up")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}
 
// Balances summary view
struct BalancesSummaryView: View {
    let members: [UserProfile]
    let totalBalances: [String: Double]
    let currentUserID: String
    let group: Group
    @State private var reminderMessages: [String: String] = [:]
    @State private var isReminding = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Outstanding Balances")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            if balanceItems.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding()
                    
                    Text("All settled up!")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(balanceItems, id: \.id) { item in
                        VStack(spacing: 8) {
                            HStack {
                                // Person icon
                                Circle()
                                    .fill(Color.teal.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(item.name.prefix(1)))
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                    )
                                
                                // Direction and amount
                                VStack(alignment: .leading, spacing: 4) {
                                    if item.amount > 0 {
                                        Text("\(item.name) owes you")
                                            .font(.subheadline)
                                    } else {
                                        Text("You owe \(item.name)")
                                            .font(.subheadline)
                                    }
                                    
                                    Text(formatCurrency(abs(item.amount)))
                                        .font(.headline)
                                        .foregroundColor(item.amount > 0 ? .green : .orange)
                                }
                                
                                Spacer()
                                
                                // Action buttons
                                HStack(spacing: 8) {
                                    if item.amount > 0 {
                                        // Show remind button if they owe you
                                        Button(action: {
                                            sendGroupReminder(to: item)
                                        }) {
                                            HStack {
                                                if isReminding && reminderMessages[item.id] == nil {
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                } else {
                                                    Text("Remind")
                                                }
                                            }
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                        }
                                        .disabled(isReminding)
                                    }
                                    
                                    // Settle button
                                    Button(action: {
                                        // Settle up action - handled by the parent view
                                    }) {
                                        Text("Settle")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.orange)
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            
                            // Show reminder message if exists
                            if let message = reminderMessages[item.id] {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 48)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // Format balance items for display
    var balanceItems: [BalanceItem] {
        var items: [BalanceItem] = []
        
        for member in members {
            if member.id == currentUserID { continue }
            
            let amount = -(totalBalances[member.id] ?? 0) // Negate because our balance calculation is inverted
            if abs(amount) > 0.01 { // Only include non-zero balances
                items.append(BalanceItem(
                    id: member.id,
                    name: member.fullName,
                    amount: amount
                ))
            }
        }
        
        return items.sorted { abs($0.amount) > abs($1.amount) } // Sort by largest amount
    }
    
    // Format currency
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // Send reminder in group context
    private func sendGroupReminder(to item: BalanceItem) {
        isReminding = true
        reminderMessages[item.id] = nil
        
        NotificationManager.shared.sendGroupReminder(
            to: item.id,
            memberName: item.name,
            group: group,
            amount: item.amount
        ) { success, error in
            DispatchQueue.main.async {
                self.isReminding = false
                
                if success {
                    self.reminderMessages[item.id] = "Reminder sent to \(item.name)"
                    // Clear the message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.reminderMessages[item.id] = nil
                    }
                } else {
                    self.reminderMessages[item.id] = error ?? "Failed to send reminder"
                }
            }
        }
    }
}
 
// Balance item
struct BalanceItem {
    let id: String
    let name: String
    let amount: Double // Positive means they owe you, negative means you owe them
}
 
