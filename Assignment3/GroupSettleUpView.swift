//
//  GroupSettleUpView.swift
//  Assignment3
//
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GroupSettleUpView: View {
    let group: Group
    let totalBalances: [String: Double]
    
    @State private var selectedMember: UserProfile?
    @State private var showingIndividualSettleUp = false
    @State private var memberProfiles: [UserProfile] = []
    @State private var isLoadingMembers = false
    @State private var reminderMessages: [String: String] = [:]
    @State private var isReminding: [String: Bool] = [:]
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = FirebaseDataManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Settle Up")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("in \(group.name)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Outstanding balances
                if isLoadingMembers {
                    ProgressView("Loading balances...")
                        .padding()
                } else if outstandingBalances.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("All settled up!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("No outstanding balances in this group")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Outstanding Balances")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(outstandingBalances) { balance in
                                VStack(spacing: 8) {
                                    HStack(spacing: 16) {
                                        // Member avatar
                                        Circle()
                                            .fill(Color.teal.opacity(0.8))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text(String(balance.member.fullName.prefix(1)))
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20, weight: .bold))
                                            )
                                        
                                        // Balance info
                                        VStack(alignment: .leading, spacing: 4) {
                                            if balance.amount > 0 {
                                                Text("\(balance.member.fullName) owes you")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("You owe \(balance.member.fullName)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Text("$\(String(format: "%.2f", abs(balance.amount)))")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(balance.amount > 0 ? .green : .orange)
                                        }
                                        
                                        Spacer()
                                        
                                        // Action button - either Remind or Settle
                                        if balance.amount > 0 {
                                            // They owe you - show Remind button
                                            Button(action: {
                                                sendReminder(to: balance)
                                            }) {
                                                HStack {
                                                    if isReminding[balance.member.id] == true {
                                                        ProgressView()
                                                            .scaleEffect(0.8)
                                                    } else {
                                                        Image(systemName: "bell")
                                                        Text("Remind")
                                                    }
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                                            .disabled(isReminding[balance.member.id] == true)
                                        } else {
                                            // You owe them - show Settle button
                                            Button(action: {
                                                selectedMember = balance.member
                                                showingIndividualSettleUp = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "dollarsign.circle")
                                                    Text("Settle")
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 16)
                                                .background(Color.orange)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    
                                    // Show reminder success message
                                    if let message = reminderMessages[balance.member.id] {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text(message)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 66)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Simplified settle all button (only for when everyone owes you)
                if !outstandingBalances.isEmpty && allBalancesArePositive {
                    VStack(spacing: 12) {
                        Button(action: {
                            sendAllReminders()
                        }) {
                            Text("Remind All")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            settleAllBalances()
                        }) {
                            Text("Mark All as Paid")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMemberProfiles()
            }
            .sheet(isPresented: $showingIndividualSettleUp) {
                if let selectedMember = selectedMember,
                   let balance = totalBalances[selectedMember.id] {
                    SettleUpView(
                        friend: Friend(
                            id: selectedMember.id,
                            name: selectedMember.fullName,
                            email: selectedMember.email,
                            amountOwed: -balance // Negate to match Friend model convention
                        ),
                        group: nil,
                        amount: -balance,
                        isUserOwing: balance > 0
                    )
                }
            }
        }
    }
    
    // Computed properties
    var outstandingBalances: [GroupBalance] {
        guard let currentUserID = dataManager.getCurrentUserID() else { return [] }
        
        var balances: [GroupBalance] = []
        
        for member in memberProfiles {
            if member.id == currentUserID { continue }
            
            let amount = -(totalBalances[member.id] ?? 0) // Negate because our balance calculation is inverted
            if abs(amount) > 0.01 { // Only include non-zero balances
                balances.append(GroupBalance(
                    member: member,
                    amount: amount
                ))
            }
        }
        
        return balances.sorted { abs($0.amount) > abs($1.amount) }
    }
    
    var allBalancesArePositive: Bool {
        return outstandingBalances.allSatisfy { $0.amount > 0 }
    }
    
    // Methods
    func loadMemberProfiles() {
        isLoadingMembers = true
        memberProfiles = []
        
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        
        for memberID in group.members {
            dispatchGroup.enter()
            
            db.collection("users").document(memberID).getDocument { snapshot, error in
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    print("Error loading member: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                let member = UserProfile(
                    id: memberID,
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    self.memberProfiles.append(member)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoadingMembers = false
        }
    }
    
    func sendReminder(to balance: GroupBalance) {
        isReminding[balance.member.id] = true
        reminderMessages[balance.member.id] = nil
        
        NotificationManager.shared.sendGroupReminder(
            to: balance.member.id,
            memberName: balance.member.fullName,
            group: group,
            amount: balance.amount
        ) { success, error in
            DispatchQueue.main.async {
                self.isReminding[balance.member.id] = false
                
                if success {
                    self.reminderMessages[balance.member.id] = "Reminder sent to \(balance.member.fullName)"
                    // Clear the message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.reminderMessages[balance.member.id] = nil
                    }
                } else {
                    // Show error briefly
                    self.reminderMessages[balance.member.id] = error ?? "Failed to send reminder"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.reminderMessages[balance.member.id] = nil
                    }
                }
            }
        }
    }
    
    func sendAllReminders() {
        for balance in outstandingBalances where balance.amount > 0 {
            sendReminder(to: balance)
        }
    }
    
    func settleAllBalances() {
        // This is a simplified implementation that marks all balances as settled
        // In a real app, you'd want to create settlement records for each transaction
        
        guard let currentUserID = dataManager.getCurrentUserID() else { return }
        
        let db = Firestore.firestore()
        
        // Create settlement records for all outstanding balances
        for balance in outstandingBalances where balance.amount > 0 {
            let settlement = Settlement(
                amount: balance.amount,
                fromUserID: balance.member.id,
                toUserID: currentUserID,
                method: "Cash", // Default method for bulk settlement
                note: "Group settlement in \(group.name)",
                status: .completed
            )
            
            db.collection("settlements").addDocument(data: settlement.toFirestoreData()) { error in
                if let error = error {
                    print("Error creating settlement: \(error.localizedDescription)")
                }
            }
        }
        
        // Update group balances to zero (simplified approach)
        for member in memberProfiles {
            if member.id == currentUserID { continue }
            
            // Find and update balance documents
            db.collection("balances")
                .whereField("users", arrayContains: currentUserID)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching balances: \(error.localizedDescription)")
                        return
                    }
                    
                    for doc in snapshot?.documents ?? [] {
                        let data = doc.data()
                        if let users = data["users"] as? [String],
                           users.contains(member.id) {
                            var amounts = data["amounts"] as? [String: Double] ?? [:]
                            amounts[currentUserID] = 0
                            amounts[member.id] = 0
                            
                            db.collection("balances").document(doc.documentID).updateData([
                                "amounts": amounts,
                                "lastUpdated": Timestamp()
                            ])
                        }
                    }
                }
        }
        
        // Dismiss the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }
}

// Supporting models
struct GroupBalance: Identifiable {
    let id = UUID()
    let member: UserProfile
    let amount: Double // Positive means they owe you, negative means you owe them
}
