//
//  FriendView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct FriendView: View {
    @StateObject private var viewModel = FriendViewModel()
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    @State private var selectedFriend: Friend?
    @State private var navigateToPayment = false
    @State private var showingFilter = false
    @State private var filterOption: FilterOption = .all
    @State private var showingRemindDialog = false
    @State private var showingSettleUpSheet = false
    @State private var isReminding = false
    @State private var reminderMessages: [String: String] = [:]
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case owesYou = "Owes You"
        case youOwe = "You Owe"
        case settled = "Settled"
        case friends = "Direct Friends"
        case groupMembers = "Group Members"
    }
    
    var filteredFriends: [Friend] {
        var result = viewModel.friends
        
        // Apply text search
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply category filter
        switch filterOption {
        case .owesYou:
            result = result.filter { $0.amountOwed > 0 }
        case .youOwe:
            result = result.filter { $0.amountOwed < 0 }
        case .settled:
            result = result.filter { $0.amountOwed == 0 }
        case .friends:
            result = result.filter { $0.groupName == nil }
        case .groupMembers:
            result = result.filter { $0.groupName != nil }
        case .all:
            // No filtering
            break
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Overall balance summary
                if !viewModel.friends.isEmpty {
                    let totalOwed = viewModel.friends.reduce(0) { $0 + $1.amountOwed }
                    
                    HStack {
                        Text("Overall, you are \(totalOwed >= 0 ? "owed" : "owe")")
                            .font(.headline)
                        
                        Text("$\(String(format: "%.2f", abs(totalOwed)))")
                            .font(.headline)
                            .foregroundColor(totalOwed >= 0 ? .green : .orange)
                        
                        Spacer()
                        
                        Button(action: {
                            showingFilter = true
                        }) {
                            HStack {
                                Text(filterOption.rawValue)
                                    .font(.subheadline)
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                
                if viewModel.isLoading {
                    ProgressView("Loading friends...")
                        .padding()
                } else if filteredFriends.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No friends found")
                            .font(.headline)
                        
                        Text("Try a different filter or add a friend")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(filteredFriends) { friend in
                            NavigationLink(destination: FriendDetailView(friend: friend)) {
                                VStack(spacing: 8) {
                                    HStack {
                                        // Avatar
                                        Circle()
                                            .fill(Color.teal.opacity(0.8))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text(String(friend.name.prefix(1).uppercased()))
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20, weight: .bold))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(friend.name)
                                                .font(.headline)
                                            
                                            if let groupName = friend.groupName {
                                                Text("from \(groupName)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            if friend.amountOwed > 0 {
                                                Text("owes you $\(String(format: "%.2f", friend.amountOwed))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.green)
                                            } else if friend.amountOwed < 0 {
                                                Text("you owe $\(String(format: "%.2f", abs(friend.amountOwed)))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.orange)
                                            } else {
                                                Text("settled up")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if friend.amountOwed != 0 {
                                            Button(action: {
                                                selectedFriend = friend
                                                if friend.amountOwed > 0 {
                                                    // Friend owes user - show remind dialog
                                                    showingRemindDialog = true
                                                } else {
                                                    // User owes friend - show settle up sheet
                                                    showingSettleUpSheet = true
                                                }
                                            }) {
                                                HStack {
                                                    if isReminding && selectedFriend?.id == friend.id {
                                                        ProgressView()
                                                            .scaleEffect(0.7)
                                                    } else {
                                                        Text(friend.amountOwed > 0 ? "Remind" : "Settle up")
                                                    }
                                                }
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(friend.amountOwed > 0 ? Color.blue : Color.orange)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                                            .disabled(isReminding)
                                        }
                                    }
                                    
                                    // Show reminder message if exists
                                    if let message = reminderMessages[friend.id] {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text(message)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 60)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search friends")
                    .listStyle(PlainListStyle())
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriendSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriendSheet) {
                AddFriendView()
            }
            .sheet(isPresented: $navigateToPayment) {
                if let friend = selectedFriend {
                    PaymentView(friend: friend, amount: friend.amountOwed)
                }
            }
            .sheet(isPresented: $showingSettleUpSheet) {
                if let friend = selectedFriend {
                    SettleUpView(
                        friend: friend,
                        group: nil,
                        amount: friend.amountOwed,
                        isUserOwing: friend.amountOwed < 0
                    )
                }
            }
            .actionSheet(isPresented: $showingFilter) {
                ActionSheet(
                    title: Text("Filter Friends"),
                    buttons: FilterOption.allCases.map { option in
                        .default(Text(option.rawValue)) { filterOption = option }
                    } + [.cancel()]
                )
            }
            .alert(isPresented: $showingRemindDialog) {
                Alert(
                    title: Text("Remind \(selectedFriend?.name ?? "friend")"),
                    message: Text("Send a reminder that they owe you $\(String(format: "%.2f", abs(selectedFriend?.amountOwed ?? 0)))?"),
                    primaryButton: .default(Text("Send")) {
                        sendReminder()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                viewModel.fetchFriends()
                // Request notification permission
                NotificationManager.shared.requestNotificationPermission()
            }
        }
    }
    
    func sendReminder() {
        guard let friend = selectedFriend else { return }
        
        isReminding = true
        reminderMessages[friend.id] = nil
        
        NotificationManager.shared.sendReminder(to: friend, amount: friend.amountOwed) { success, error in
            DispatchQueue.main.async {
                self.isReminding = false
                
                if success {
                    self.reminderMessages[friend.id] = "Reminder sent"
                    // Clear the message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.reminderMessages[friend.id] = nil
                    }
                } else {
                    // Show error
                    self.reminderMessages[friend.id] = error ?? "Failed to send reminder"
                }
            }
        }
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView()
    }
}
