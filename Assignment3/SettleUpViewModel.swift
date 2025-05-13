//
//  SettleUpViewModel.swift
//  Assignment3
//

//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class SettleUpViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var settlementCompleted = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    // Record payment between friends
    func recordFriendPayment(friend: Friend, amount: Double, paymentMethod: PaymentMethod, note: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in"
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        // Create settlement record
        let settlement = Settlement(
            amount: abs(amount),
            fromUserID: currentUserID,
            toUserID: friend.id,
            method: paymentMethod.name,
            note: note,
            status: .completed
        )
        
        // Save settlement to Firestore
        db.collection("settlements").addDocument(data: settlement.toFirestoreData()) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.isProcessing = false
                self.errorMessage = "Error recording settlement: \(error.localizedDescription)"
                return
            }
            
            // Update balance between users
            self.updateFriendBalance(
                currentUserID: currentUserID,
                friendID: friend.id,
                amount: amount
            ) { success in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if success {
                        self.settlementCompleted = true
                    }
                }
            }
        }
    }
    
    // Record payment in a group context
    func recordGroupPayment(group: Group, amount: Double, paymentMethod: PaymentMethod, note: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in"
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        // For group settlements, we need to determine who pays whom
        // This is a simplified implementation - in reality, you'd need more complex logic
        // to handle multi-person settlements
        
        // Create a general settlement record
        let settlement = Settlement(
            amount: abs(amount),
            fromUserID: currentUserID,
            toUserID: "group_settlement", // Special indicator for group settlements
            method: paymentMethod.name,
            note: note,
            status: .completed
        )
        
        // Save settlement
        db.collection("settlements").addDocument(data: settlement.toFirestoreData()) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.isProcessing = false
                self.errorMessage = "Error recording settlement: \(error.localizedDescription)"
                return
            }
            
            // For group settlements, you'd need to update balances between multiple users
            // This is a placeholder - implement according to your specific business logic
            self.updateGroupBalances(groupID: group.id ?? "", currentUserID: currentUserID) { success in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if success {
                        self.settlementCompleted = true
                    }
                }
            }
        }
    }
    
    private func updateFriendBalance(currentUserID: String, friendID: String, amount: Double, completion: @escaping (Bool) -> Void) {
        db.collection("balances")
            .whereField("users", arrayContains: currentUserID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    self.errorMessage = "Error updating balance: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                var balanceDocID: String?
                var currentAmounts: [String: Double]?
                
                // Find existing balance document
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
                    // Update existing balance - zero out the settled amount
                    amounts[currentUserID] = 0
                    amounts[friendID] = 0
                    
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
                    // This shouldn't happen if there's a debt, but handle gracefully
                    completion(true)
                }
            }
    }
    
    private func updateGroupBalances(groupID: String, currentUserID: String, completion: @escaping (Bool) -> Void) {
        // Simplified implementation - you may need more complex logic here
        // depending on how you want to handle group settlements
        
        // For now, let's just mark as completed
        // In a real implementation, you'd update all relevant balances in the group
        completion(true)
    }
}
