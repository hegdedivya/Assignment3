//
//  FriendViewModel.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FriendViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var isLoading = true
    @Published var errorMessage = ""
    @Published var searchResults: [Friend] = []
    @Published var isSearching = false
    @Published var sharedActivities: [Activity] = []
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // Get all friends for the current user
    func fetchFriends() {
        isLoading = true
        errorMessage = ""
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to view friends"
            isLoading = false
            return
        }
        
        // Get current user's friend list
        db.collection("users").document(currentUserID).collection("friends").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Error fetching friends: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            var tempFriends: [Friend] = []
            let group = DispatchGroup()
            
            for doc in snapshot?.documents ?? [] {
                let friendID = doc.documentID
                
                group.enter()
                
                // Get friend's user information
                self.db.collection("users").document(friendID).getDocument { userSnapshot, userError in
                    defer { group.leave() }
                    
                    if let userError = userError {
                        print("Error fetching user details: \(userError)")
                        return
                    }
                    
                    guard let userData = userSnapshot?.data(),
                          let firstName = userData["firstName"] as? String,
                          let lastName = userData["lastName"] as? String,
                          let email = userData["email"] as? String else {
                        return
                    }
                    
                    // Get balance information for this friend
                    group.enter()
                    self.db.collection("balances")
                        .whereField("users", arrayContains: currentUserID)
                        .getDocuments { balanceSnapshot, balanceError in
                            defer { group.leave() }
                            
                            if let balanceError = balanceError {
                                print("Error fetching balances: \(balanceError)")
                                return
                            }
                            
                            var totalOwed: Double = 0
                            
                            for balanceDoc in balanceSnapshot?.documents ?? [] {
                                let balanceData = balanceDoc.data()
                                if let users = balanceData["users"] as? [String],
                                   users.contains(friendID),
                                   let amounts = balanceData["amounts"] as? [String: Double] {
                                    
                                    // Calculate balance situation
                                    if let currentUserAmount = amounts[currentUserID],
                                       let friendAmount = amounts[friendID] {
                                        totalOwed += (friendAmount - currentUserAmount)
                                    }
                                }
                            }
                            
                            // Create friend object
                            let friend = Friend(
                                id: friendID,
                                name: "\(firstName) \(lastName)",
                                email: email,
                                imageURL: userData["profileImageURL"] as? String,
                                amountOwed: totalOwed
                            )
                            
                            tempFriends.append(friend)
                        }
                }
            }
            
            group.notify(queue: .main) {
                self.friends = tempFriends
                self.isLoading = false
            }
        }
    }
    
    // Search for users by email
    func searchUserByEmail(_ email: String) {
        guard !email.isEmpty else {
            errorMessage = "Please enter an email address"
            return
        }
        
        isSearching = true
        errorMessage = ""
        searchResults = []
        
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isSearching = false
                
                if let error = error {
                    self.errorMessage = "Search error: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self.errorMessage = "User not found"
                    return
                }
                
                var results: [Friend] = []
                
                for doc in documents {
                    let data = doc.data()
                    guard let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let email = data["email"] as? String else {
                        continue
                    }
                    
                    let friend = Friend(
                        id: doc.documentID,
                        name: "\(firstName) \(lastName)",
                        email: email,
                        imageURL: data["profileImageURL"] as? String,
                        amountOwed: 0
                    )
                    
                    results.append(friend)
                }
                
                DispatchQueue.main.async {
                    self.searchResults = results
                }
            }
    }
    
    // Add a new friend
    func addFriend(_ friend: Friend, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(false, "You must be logged in to add friends")
            return
        }
        
        // Get the friend's user ID
        let friendID = friend.id
        
        // Add friend to current user's friend list
        db.collection("users").document(currentUserID).collection("friends").document(friendID).setData([
            "addedAt": Timestamp()
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, "Failed to add friend: \(error.localizedDescription)")
                return
            }
            
            // Add current user to friend's friend list (reciprocal)
            self.db.collection("users").document(friendID).collection("friends").document(currentUserID).setData([
                "addedAt": Timestamp()
            ]) { error in
                if let error = error {
                    completion(false, "Failed to add friend: \(error.localizedDescription)")
                    return
                }
                
                // Successfully added friend
                DispatchQueue.main.async {
                    if !self.friends.contains(where: { $0.id == friend.id }) {
                        self.friends.append(friend)
                    }
                }
                
                completion(true, nil)
            }
        }
    }
    
    // Fetch shared activities with a specific friend
    func fetchSharedActivities(with friend: Friend) {
        isLoading = true
        sharedActivities = []
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        // Get the friend's user ID based on email
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding friend: \(error)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    self.isLoading = false
                    return
                }
                
                // Query activities that both users are part of
                self.db.collection("activities")
                    .whereField("members", arrayContains: currentUserID)
                    .getDocuments { [weak self] activitySnapshot, activityError in
                        guard let self = self else { return }
                        
                        if let activityError = activityError {
                            print("Error fetching activities: \(activityError)")
                            self.isLoading = false
                            return
                        }
                        
                        var sharedActivities: [Activity] = []
                        
                        for doc in activitySnapshot?.documents ?? [] {
                            let data = doc.data()
                            let id = doc.documentID
                            
                            guard let name = data["name"] as? String,
                                  let timestamp = data["date"] as? Timestamp,
                                  let members = data["members"] as? [String],
                                  members.contains(friendID),
                                  let expenseArray = data["expenses"] as? [[String: Any]] else {
                                continue
                            }
                            
                            let date = timestamp.dateValue()
                            
                            // Parse expenses
                            let expenses: [Expense] = expenseArray.compactMap { dict in
                                guard let itemName = dict["itemName"] as? String,
                                      let amount = dict["amount"] as? Double else {
                                    return nil
                                }
                                return Expense(itemName: itemName, amount: amount)
                            }
                            
                            let activity = Activity(id: id, name: name, date: date, members: members, expenses: expenses)
                            sharedActivities.append(activity)
                        }
                        
                        DispatchQueue.main.async {
                            self.sharedActivities = sharedActivities
                            self.isLoading = false
                        }
                    }
            }
    }
}
