//
//  FriendDetailView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//
 
import SwiftUI
 
// Friend to Group adapter extension
extension Friend {
    func toGroup() -> Group {
        // Get current user ID
        let currentUserID = FirebaseDataManager.shared.getCurrentUserID() ?? ""
        
        // Create a Group with the friend and current user as members
        return Group(
            id: self.id,
            name: self.groupName ?? "Expense with \(self.name)",
            members: [currentUserID, self.id ?? ""],
            createdAt: Date(),
            type: "Friend",
            createdBy: currentUserID
        )
    }
}
 
struct FriendDetailView: View {
    var friend: Friend
    @StateObject private var viewModel = FriendViewModel()
    @State private var showingPaymentSheet = false
    @State private var showingAddExpenseSheet = false
    @State private var showingRemindDialog = false
    @State private var showingSettleUpSheet = false
    @State private var isReminding = false
    @State private var reminderMessage = ""
    
    var body: some View {
        VStack {
            // Friend profile card
            VStack(spacing: 10) {
                Circle()
                    .fill(Color.teal.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(friend.name.prefix(1).uppercased()))
                            .foregroundColor(.white)
                            .font(.system(size: 36, weight: .bold))
                    )
                
                Text(friend.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let groupName = friend.groupName {
                    Text("from \(groupName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if friend.amountOwed > 0 {
                    Text("\(friend.name) owes you $\(String(format: "%.2f", friend.amountOwed))")
                        .font(.headline)
                        .foregroundColor(.green)
                } else if friend.amountOwed < 0 {
                    Text("You owe \(friend.name) $\(String(format: "%.2f", abs(friend.amountOwed)))")
                        .font(.headline)
                        .foregroundColor(.orange)
                } else {
                    Text("All settled up")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 20) {
                    if friend.amountOwed != 0 {
                        Button(action: {
                            if friend.amountOwed > 0 {
                                // Friend owes user - show remind dialog
                                showingRemindDialog = true
                            } else {
                                // User owes friend - show settle up sheet
                                showingSettleUpSheet = true
                            }
                        }) {
                            HStack {
                                if isReminding {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 4)
                                }
                                Text(friend.amountOwed > 0 ? "Remind" : "Settle up")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(friend.amountOwed > 0 ? Color.blue : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isReminding)
                    }
                    
                    Button(action: {
                        showingAddExpenseSheet = true
                    }) {
                        Text("Add expense")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Show reminder success message
            if !reminderMessage.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(reminderMessage)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Shared activities list using your existing Activity model
            VStack(alignment: .leading) {
                Text("Shared Activities")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if viewModel.sharedActivities.isEmpty {
                    Text("No shared activities")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.sharedActivities) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                VStack(alignment: .leading) {
                                    Text(activity.name)
                                        .font(.headline)
                                    Text("Date: \(activity.date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.subheadline)
                                    
                                    // Show total expenses
                                    if !activity.expenses.isEmpty {
                                        let totalAmount = activity.expenses.reduce(0) { $0 + $1.amount }
                                        Text("Total: $\(String(format: "%.2f", totalAmount))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            
            Spacer()
        }
        .navigationTitle(friend.name)
        .onAppear {
            viewModel.loadSharedActivitiesBetweenUsers(with: friend)
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentView(friend: friend, amount: friend.amountOwed)
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            AddExpenseView(group: friend.toGroup())
        }
        .sheet(isPresented: $showingSettleUpSheet) {
            SettleUpView(
                friend: friend,
                group: nil,
                amount: friend.amountOwed,
                isUserOwing: friend.amountOwed < 0
            )
        }
        .alert(isPresented: $showingRemindDialog) {
            Alert(
                title: Text("Remind \(friend.name)"),
                message: Text("Send a reminder that they owe you $\(String(format: "%.2f", friend.amountOwed))?"),
                primaryButton: .default(Text("Send")) {
                    sendReminder()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func sendReminder() {
        isReminding = true
        reminderMessage = ""
        
        NotificationManager.shared.sendReminder(to: friend, amount: friend.amountOwed) { success, error in
            DispatchQueue.main.async {
                self.isReminding = false
                
                if success {
                    self.reminderMessage = "Reminder sent to \(friend.name)"
                    // Clear the message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.reminderMessage = ""
                    }
                } else {
                    // Show error
                    self.reminderMessage = error ?? "Failed to send reminder"
                }
            }
        }
    }
}
 
struct FriendDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FriendDetailView(friend: Friend(id: "1", name: "John Doe", email: "john@example.com", amountOwed: 25.0))
        }
    }
}
 
