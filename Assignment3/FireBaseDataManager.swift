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
    @Published var userGroups: [GroupData] = []
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
    // Add this function to your FirebaseDataManager class
    func getCurrentUserID() -> String? {
        // First try to get from currentUser
        if let userID = currentUser?.id, !userID.isEmpty {
            return userID
        }
        
        // Fallback to Auth if currentUser is not loaded yet
        return Auth.auth().currentUser?.uid
    }
    
    
    /// Fetch groups that the user belongs to
    private func fetchUserGroups(userID: String) {
        isLoadingGroups = true
        
        // Query groups where user is a member
        let query = db.collection("Group")
            .whereField("Members", arrayContains: userID)
        
        // Remove existing listener
        listeners["groups"]?.remove()
        
        // Set up new listener
        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoadingGroups = false
            
            if let error = error {
                self.errorMessage = "Error fetching groups: \(error.localizedDescription)"
                return
            }
            
            var groups: [GroupData] = []
            
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                
                let group = GroupData(
                    id: document.documentID,
                    name: data["Name"] as? String ?? "",
                    members: data["Members"] as? [String] ?? [],
                    transactions: data["Transactions"] as? [String] ?? [],
                    expenses: data["Expenses"] as? [Double] ?? []
                )
                
                groups.append(group)
            }
            
            DispatchQueue.main.async {
                self.userGroups = groups
            }
        }
        
        listeners["groups"] = listener
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
}

// MARK: - Data Models

struct UserProfile {
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
