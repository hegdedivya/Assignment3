//
//  FireBaseDataManager.swift
//  Assignment3
//
//  Created by Minkun He on 11/5/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseDataManager: ObservableObject {
    // Singleton instance
    static let shared = FirebaseDataManager()
    
    // User data
    @Published var currentUser: UserProfile?
    @Published var userGroups: [GroupData] = [] // Keep as GroupData for now
    @Published var groups: [Group] = [] // New property for Group objects
    @Published var userActivities: [ActivityData] = []
    @Published var userTransactions: [TransactionData] = []
    
    // Loading states
    @Published var isLoadingUser = false
    @Published var isLoadingGroups = false
    @Published var isLoadingActivities = false
    @Published var isLoadingTransactions = false
    
    // Error handling
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {}
    
    // MARK: - Main Functions
    
    /// Call this function right after login is successful
    func fetchUserDataAfterLogin() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in"
            return
        }
        
        // Fetch user profile
        fetchUserProfile(userID: user.uid)
        
        // Fetch related data
        fetchUserGroups(userID: user.uid)
        fetchUserActivities(userID: user.uid)
        fetchUserTransactions(userID: user.uid)
    }
    
    // Get current user ID
    func getCurrentUserID() -> String? {
        // First try to get from currentUser
        if let userID = currentUser?.id, !userID.isEmpty {
            return userID
        }
        
        // Fallback to Auth if currentUser is not loaded yet
        return Auth.auth().currentUser?.uid
    }
    
    // Fetch groups for a user
    func fetchUserGroups(userID: String) {
        isLoadingGroups = true
        
        // Remove existing listener
        listeners["groups"]?.remove()
        
        // Query groups where user is a member
        let listener = db.collection("Group")
            .whereField("members", arrayContains: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoadingGroups = false
                
                if let error = error {
                    self.errorMessage = "Error fetching groups: \(error.localizedDescription)"
                    return
                }
                
                var groups: [Group] = []
                
                for document in snapshot?.documents ?? [] {
                    let data = document.data()
                    
                    let name = data["name"] as? String ?? ""
                    let members = data["members"] as? [String] ?? []
                    let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    let type = data["type"] as? String
                    let createdBy = data["createdBy"] as? String
                    
                    let group = Group(
                        id: document.documentID,
                        name: name,
                        members: members,
                        createdAt: timestamp.dateValue(),
                        type: type,
                        createdBy: createdBy
                    )
                    
                    groups.append(group)
                }
                
                DispatchQueue.main.async {
                    // Update both group properties
                    self.groups = groups
                    
                    // Convert Group objects to GroupData objects
                    self.userGroups = groups.map { group in
                        return GroupData(
                            id: group.id ?? "",
                            name: group.name,
                            members: group.members,
                            transactions: [], // Default empty arrays
                            expenses: []      // Default empty arrays
                        )
                    }
                }
            }
        
        listeners["groups"] = listener
    }
    
    /// Call this function when logging out
    func clearUserData() {
        // Remove all listeners
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
        
        // Clear all data
        DispatchQueue.main.async {
            self.currentUser = nil
            self.userGroups = []
            self.groups = []
            self.userActivities = []
            self.userTransactions = []
            self.errorMessage = nil
        }
    }
    
    // MARK: - Data Fetching Functions
    
    /// Fetch user profile
    private func fetchUserProfile(userID: String) {
        isLoadingUser = true
        errorMessage = nil
        
        // Remove existing listener
        listeners["user"]?.remove()
        
        // Set up new listener
        let listener = db.collection("users").document(userID)
            .addSnapshotListener { [weak self] document, error in
                guard let self = self else { return }
                
                self.isLoadingUser = false
                
                if let error = error {
                    self.errorMessage = "Error fetching user data: \(error.localizedDescription)"
                    return
                }
                
                guard let document = document, document.exists else {
                    self.errorMessage = "User document not found"
                    return
                }
                
                let data = document.data() ?? [:]
                
                // Create user profile from document data
                let userProfile = UserProfile(
                    id: userID,
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    self.currentUser = userProfile
                }
            }
        
        listeners["user"] = listener
    }
    
    /// Fetch activities involving the user
    private func fetchUserActivities(userID: String) {
        isLoadingActivities = true
        
        // Query activities where user is a member
        let query = db.collection("activities")
            .whereField("members", arrayContains: userID)
        
        // Remove existing listener
        listeners["activities"]?.remove()
        
        // Set up new listener
        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoadingActivities = false
            
            if let error = error {
                self.errorMessage = "Error fetching activities: \(error.localizedDescription)"
                return
            }
            
            var activities: [ActivityData] = []
            
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                
                // Get expenses from activity
                var expenses: [ExpenseData] = []
                if let expensesArray = data["expenses"] as? [[String: Any]] {
                    for (index, expenseDict) in expensesArray.enumerated() {
                        let expense = ExpenseData(
                            id: String(index),
                            itemName: expenseDict["itemName"] as? String ?? "",
                            amount: expenseDict["amount"] as? Double ?? 0
                        )
                        expenses.append(expense)
                    }
                }
                
                // Create activity object
                let timestamp = data["date"] as? Timestamp
                let activity = ActivityData(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    date: timestamp?.dateValue() ?? Date(),
                    members: data["members"] as? [String] ?? [],
                    expenses: expenses
                )
                
                activities.append(activity)
            }
            
            DispatchQueue.main.async {
                self.userActivities = activities
            }
        }
        
        listeners["activities"] = listener
    }
    
    /// Fetch transactions involving the user
    private func fetchUserTransactions(userID: String) {
        isLoadingTransactions = true
        
        // We need two queries: one for 'from' and one for 'to'
        let fromQuery = db.collection("Transactions")
            .whereField("from", isEqualTo: userID)
        
        let toQuery = db.collection("Transactions")
            .whereField("to", isEqualTo: userID)
        
        // Remove existing listeners
        listeners["transactions_from"]?.remove()
        listeners["transactions_to"]?.remove()
        
        // Set up new listeners
        let fromListener = fromQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.processTransactions(snapshot: snapshot, error: error, userID: userID)
        }
        
        let toListener = toQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.processTransactions(snapshot: snapshot, error: error, userID: userID)
        }
        
        listeners["transactions_from"] = fromListener
        listeners["transactions_to"] = toListener
    }
    
    // Helper function to process transaction documents
    private func processTransactions(snapshot: QuerySnapshot?, error: Error?, userID: String) {
        if let error = error {
            self.errorMessage = "Error fetching transactions: \(error.localizedDescription)"
            return
        }
        
        var updatedTransactions = self.userTransactions
        
        for document in snapshot?.documents ?? [] {
            let data = document.data()
            
            // Skip if this transaction is already in our list
            if updatedTransactions.contains(where: { $0.id == document.documentID }) {
                continue
            }
            
            // Get transaction data
            let timestamp = data["SettledAt"] as? Timestamp
            let transaction = TransactionData(
                id: document.documentID,
                amount: data["Amount"] as? Double ?? 0,
                from: data["from"] as? String ?? "",
                to: data["to"] as? String ?? "",
                date: timestamp?.dateValue() ?? Date(),
                expenseID: data["ExpenseID"] as? String,
                groupID: data["GroupID"] as? String
            )
            
            updatedTransactions.append(transaction)
        }
        
        DispatchQueue.main.async {
            self.userTransactions = updatedTransactions
            self.isLoadingTransactions = false
        }
    }
    
    // MARK: - Create and Update Methods
    
    /// Create a new group
    func createGroup(name: String, type: String, members: [String], completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            completion(false, "You must be logged in to create a group")
            return
        }
        
        // Include the current user in the members list if not already included
        var allMembers = members
        if !allMembers.contains(currentUserID) {
            allMembers.append(currentUserID)
        }
        
        // Create group data
        let groupData: [String: Any] = [
            "name": name,
            "type": type,
            "members": allMembers,
            "createdBy": currentUserID,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add to Firestore
        db.collection("Group").document().setData(groupData) { error in
            if let error = error {
                completion(false, "Error creating group: \(error.localizedDescription)")
                return
            }
            
            // Refresh groups
            self.fetchUserGroups(userID: currentUserID)
            completion(true, nil)
        }
    }
    
    /// Add a user to an existing group
    func addUserToGroup(groupID: String, userID: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("Group").document(groupID).updateData([
            "members": FieldValue.arrayUnion([userID])
        ]) { error in
            if let error = error {
                completion(false, "Error adding user to group: \(error.localizedDescription)")
                return
            }
            
            // Group data will be refreshed automatically via listener
            completion(true, nil)
        }
    }
    
    /// Create a new activity
    func createActivity(name: String, date: Date, members: [String], expenses: [ExpenseData], completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            completion(false, "You must be logged in to create an activity")
            return
        }
        
        // Include the current user in the members list if not already included
        var allMembers = members
        if !allMembers.contains(currentUserID) {
            allMembers.append(currentUserID)
        }
        
        // Convert expenses to the format expected by Firestore
        let expensesData = expenses.map { expense in
            [
                "itemName": expense.itemName,
                "amount": expense.amount
            ]
        }
        
        // Create activity data
        let activityData: [String: Any] = [
            "name": name,
            "date": Timestamp(date: date),
            "members": allMembers,
            "expenses": expensesData
        ]
        
        // Add to Firestore
        db.collection("activities").document().setData(activityData) { error in
            if let error = error {
                completion(false, "Error creating activity: \(error.localizedDescription)")
                return
            }
            
            // Refresh activities
            self.fetchUserActivities(userID: currentUserID)
            completion(true, nil)
        }
    }

    /// Update an existing activity
    func updateActivity(activityID: String, name: String, date: Date, members: [String], expenses: [ExpenseData], completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            completion(false, "You must be logged in to update an activity")
            return
        }
        
        // Convert expenses to the format expected by Firestore
        let expensesData = expenses.map { expense in
            [
                "itemName": expense.itemName,
                "amount": expense.amount
            ]
        }
        
        let activityData: [String: Any] = [
            "name": name,
            "date": Timestamp(date: date),
            "members": members,
            "expenses": expensesData
        ]
        
        db.collection("activities").document(activityID).updateData(activityData) { error in
            if let error = error {
                completion(false, "Error updating activity: \(error.localizedDescription)")
                return
            }
            
            // Activities will be refreshed automatically via listener
            completion(true, nil)
        }
    }

    /// Delete an activity
    func deleteActivity(activityID: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("activities").document(activityID).delete { error in
            if let error = error {
                completion(false, "Error deleting activity: \(error.localizedDescription)")
                return
            }
            
            // Activity will be removed automatically via listener
            completion(true, nil)
        }
    }

    // MARK: - Friend Management

    /// Search for users by email
    func searchUsersByEmail(_ email: String, completion: @escaping ([UserProfile], String?) -> Void) {
        guard !email.isEmpty else {
            completion([], "Please enter an email address")
            return
        }
        
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], "Search error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([], "User not found")
                    return
                }
                
                var results: [UserProfile] = []
                
                for doc in documents {
                    let data = doc.data()
                    let userProfile = UserProfile(
                        id: doc.documentID,
                        email: data["email"] as? String ?? "",
                        firstName: data["firstName"] as? String ?? "",
                        lastName: data["lastName"] as? String ?? "",
                        phoneNumber: data["phoneNumber"] as? String ?? ""
                    )
                    results.append(userProfile)
                }
                
                completion(results, nil)
            }
    }

    /// Add a friend
    func addFriend(friendID: String, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            completion(false, "You must be logged in to add friends")
            return
        }
        
        // Add friend to current user's friend list
        db.collection("users").document(currentUserID).collection("friends").document(friendID).setData([
            "addedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                completion(false, "Failed to add friend: \(error.localizedDescription)")
                return
            }
            
            // Add current user to friend's friend list (reciprocal)
            self.db.collection("users").document(friendID).collection("friends").document(currentUserID).setData([
                "addedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    completion(false, "Failed to add friend: \(error.localizedDescription)")
                    return
                }
                
                completion(true, nil)
            }
        }
    }

    /// Fetch user's friends
    func fetchUserFriends(userID: String, completion: @escaping ([UserProfile], String?) -> Void) {
        db.collection("users").document(userID).collection("friends").getDocuments { friendSnapshot, error in
            if let error = error {
                completion([], "Error fetching friends: \(error.localizedDescription)")
                return
            }
            
            var friends: [UserProfile] = []
            let dispatchGroup = DispatchGroup()
            
            for friendDoc in friendSnapshot?.documents ?? [] {
                let friendID = friendDoc.documentID
                
                dispatchGroup.enter()
                self.db.collection("users").document(friendID).getDocument { userSnapshot, userError in
                    defer { dispatchGroup.leave() }
                    
                    if let userError = userError {
                        print("Error fetching friend details: \(userError)")
                        return
                    }
                    
                    guard let userData = userSnapshot?.data() else {
                        print("Friend data not found")
                        return
                    }
                    
                    let friend = UserProfile(
                        id: friendID,
                        email: userData["email"] as? String ?? "",
                        firstName: userData["firstName"] as? String ?? "",
                        lastName: userData["lastName"] as? String ?? "",
                        phoneNumber: userData["phoneNumber"] as? String ?? ""
                    )
                    
                    friends.append(friend)
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(friends, nil)
            }
        }
    }

    // MARK: - Expense Management

    /// Create a new expense
    func createExpense(name: String, amount: Double, groupID: String, paidBy: String?, completion: @escaping (Bool, String?) -> Void) {
        guard getCurrentUserID() != nil else {
            completion(false, "You must be logged in to create an expense")
            return
        }
        
        let expenseData: [String: Any] = [
            "name": name,
            "amount": amount,
            "groupID": groupID,
            "paidBy": paidBy ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("expenses").document().setData(expenseData) { error in
            if let error = error {
                completion(false, "Error creating expense: \(error.localizedDescription)")
                return
            }
            
            completion(true, nil)
        }
    }

    /// Update an existing expense
    func updateExpense(expenseID: String, name: String, amount: Double, groupID: String, paidBy: String?, completion: @escaping (Bool, String?) -> Void) {
        let expenseData: [String: Any] = [
            "name": name,
            "amount": amount,
            "groupID": groupID,
            "paidBy": paidBy ?? ""
        ]
        
        db.collection("expenses").document(expenseID).updateData(expenseData) { error in
            if let error = error {
                completion(false, "Error updating expense: \(error.localizedDescription)")
                return
            }
            
            completion(true, nil)
        }
    }

    /// Delete an expense
    func deleteExpense(expenseID: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("expenses").document(expenseID).delete { error in
            if let error = error {
                completion(false, "Error deleting expense: \(error.localizedDescription)")
                return
            }
            
            completion(true, nil)
        }
    }

    // MARK: - Transaction Management

    /// Create a new transaction
    func createTransaction(amount: Double, from: String, to: String, expenseID: String?, groupID: String?, completion: @escaping (Bool, String?) -> Void) {
        let transactionData: [String: Any] = [
            "Amount": amount,
            "from": from,
            "to": to,
            "SettledAt": FieldValue.serverTimestamp(),
            "ExpenseID": expenseID ?? "",
            "GroupID": groupID ?? ""
        ]
        
        db.collection("Transactions").document().setData(transactionData) { error in
            if let error = error {
                completion(false, "Error creating transaction: \(error.localizedDescription)")
                return
            }
            
            // Refresh transactions
            if let currentUserID = self.getCurrentUserID() {
                self.fetchUserTransactions(userID: currentUserID)
            }
            completion(true, nil)
        }
    }

    /// Update transaction status
    func updateTransaction(transactionID: String, newData: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        db.collection("Transactions").document(transactionID).updateData(newData) { error in
            if let error = error {
                completion(false, "Error updating transaction: \(error.localizedDescription)")
                return
            }
            
            completion(true, nil)
        }
    }
}

// MARK: - Data Models

struct UserProfile: Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct GroupData: Identifiable {
    let id: String
    let name: String
    let members: [String]
    let transactions: [String]
    let expenses: [Double]
}

struct ActivityData: Identifiable {
    let id: String
    let name: String
    let date: Date
    let members: [String]
    let expenses: [ExpenseData]
}

struct ExpenseData: Identifiable {
    let id: String
    let itemName: String
    let amount: Double
}

struct TransactionData: Identifiable {
    let id: String
    let amount: Double
    let from: String
    let to: String
    let date: Date
    let expenseID: String?
    let groupID: String?
}

