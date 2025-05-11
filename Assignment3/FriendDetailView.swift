// FriendDetailView.swift
// FriendDetailView.swift

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
                                // User owes friend - proceed to payment
                                showingPaymentSheet = true
                            }
                        }) {
                            Text(friend.amountOwed > 0 ? "Remind" : "Settle up")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(friend.amountOwed > 0 ? Color.blue : Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
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
            
            // Shared activities list
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
                                    
                                    // Add activity-related balance info here
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
            viewModel.fetchSharedActivities(with: friend)
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentView(friend: friend, amount: friend.amountOwed)
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            AddExpenseView(group: friend.toGroup())
        }
        .alert(isPresented: $showingRemindDialog) {
            Alert(
                title: Text("Remind \(friend.name)"),
                message: Text("Send a reminder that they owe you $\(String(format: "%.2f", friend.amountOwed))?"),
                primaryButton: .default(Text("Send")) {
                    // In a real app, this would send a push notification
                    print("Reminder sent to \(friend.name)")
                },
                secondaryButton: .cancel()
            )
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
