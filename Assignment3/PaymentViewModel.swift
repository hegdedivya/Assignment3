//
//  PaymentViewModel.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class PaymentViewModel: ObservableObject {
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var isProcessing = false
    @Published var paymentCompleted = false
    @Published var errorMessage = ""
    @Published var paymentNote = ""
    
    private let db = Firestore.firestore()
    
    // Process a payment to a friend
    func processPayment(to friend: Friend, amount: Double, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to make payments"
            completion(false)
            return
        }
        
        guard let paymentMethod = selectedPaymentMethod else {
            errorMessage = "Please select a payment method"
            completion(false)
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        // Get friend's user ID using their email
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isProcessing = false
                    self.errorMessage = "Error processing payment: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    self.isProcessing = false
                    self.errorMessage = "Friend not found"
                    completion(false)
                    return
                }
                
                // Create a new settlement
                let settlement = Settlement(
                    amount: abs(amount),
                    fromUserID: amount > 0 ? friendID : currentUserID, // If amount is positive, friend owes you
                    toUserID: amount > 0 ? currentUserID : friendID,   // If amount is positive, payment is from friend to you
                    method: paymentMethod.name,
                    note: self.paymentNote
                )
                
                // Save settlement to Firestore
                self.db.collection("settlements").addDocument(data: settlement.toFirestoreData()) { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.isProcessing = false
                        self.errorMessage = "Error saving settlement: \(error.localizedDescription)"
                        completion(false)
                        return
                    }
                    
                    // Update balances
                    self.updateBalances(currentUserID: currentUserID, friendID: friendID, amount: amount) { success in
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            
                            if success {
                                self.paymentCompleted = true
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                    }
                }
            }
    }
    
    // Update balances between users after a payment
    private func updateBalances(currentUserID: String, friendID: String, amount: Double, completion: @escaping (Bool) -> Void) {
        // Find balance records between current user and friend
        db.collection("balances")
            .whereField("users", arrayContains: currentUserID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    self.errorMessage = "Error updating balances: \(error.localizedDescription)"
                    completion(false)
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
                
                if let balanceDocID = balanceDocID, var amounts = currentAmounts {
                    // Update existing balance
                    if amount > 0 {
                        // Friend pays you
                        amounts[friendID] = (amounts[friendID] ?? 0) - abs(amount)
                    } else {
                        // You pay friend
                        amounts[currentUserID] = (amounts[currentUserID] ?? 0) - abs(amount)
                    }
                    
                    self.db.collection("balances").document(balanceDocID).updateData([
                        "amounts": amounts,
                        "lastUpdated": Timestamp()
                    ]) { error in
                        if let error = error {
                            self.errorMessage = "Error updating balance: \(error.localizedDescription)"
                            completion(false)
                        } else {
                            completion(true)
                        }
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
                    
                    self.db.collection("balances").addDocument(data: balanceData) { error in
                        if let error = error {
                            self.errorMessage = "Error creating balance record: \(error.localizedDescription)"
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
            }
    }
    
    // Add a new expense with a friend
    func addExpense(name: String, amount: Double, date: Date, friend: Friend, paidByFriend: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard let amount = Double(String(format: "%.2f", amount)), amount > 0 else {
            completion(false, "Please enter a valid amount")
            return
        }
        
        guard !name.isEmpty else {
            completion(false, "Please enter an expense name")
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(false, "You must be logged in to add expenses")
            isProcessing = false
            return
        }
        
        // Get friend's user ID
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isProcessing = false
                    completion(false, "Error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    self.isProcessing = false
                    completion(false, "Friend not found")
                    return
                }
                
                // Create new activity for this expense
                let activityData: [String: Any] = [
                    "name": name,
                    "date": Timestamp(date: date),
                    "members": [currentUserID, friendID],
                    "expenses": [
                        [
                            "itemName": name,
                            "amount": amount,
                            "paidBy": paidByFriend ? friendID : currentUserID,
                            "splitWith": [currentUserID, friendID]
                        ]
                    ],
                    "createdBy": currentUserID,
                    "createdAt": Timestamp()
                ]
                
                self.db.collection("activities").addDocument(data: activityData) { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.isProcessing = false
                        completion(false, "Error adding expense: \(error.localizedDescription)")
                        return
                    }
                    
                    // Update balances
                    let perPersonAmount = amount / 2.0
                    
                    // Find balance document
                    self.db.collection("balances")
                        .whereField("users", arrayContains: currentUserID)
                        .getDocuments { [weak self] balanceSnapshot, balanceError in
                            guard let self = self else { return }
                            
                            if let balanceError = balanceError {
                                self.isProcessing = false
                                completion(false, "Error updating balances: \(balanceError.localizedDescription)")
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
                                
                                self.db.collection("balances").document(balanceDocID).updateData([
                                    "amounts": amounts,
                                    "lastUpdated": Timestamp()
                                ]) { error in
                                    self.isProcessing = false
                                    
                                    if let error = error {
                                        completion(false, "Error updating balance: \(error.localizedDescription)")
                                    } else {
                                        completion(true, nil)
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
                                
                                self.db.collection("balances").addDocument(data: balanceData) { error in
                                    self.isProcessing = false
                                    
                                    if let error = error {
                                        completion(false, "Error creating balance: \(error.localizedDescription)")
                                    } else {
                                        completion(true, nil)
                                    }
                                }
                            }
                        }
                }
            }
    }
}
