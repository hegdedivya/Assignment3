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
    
    // Get all friends for the current user including group members
    func fetchFriends() {
        isLoading = true
        errorMessage = ""
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to view friends"
            isLoading = false
            return
        }
        
        var allFriends: [Friend] = []
        let dispatchGroup = DispatchGroup()
        
        // Step 1: Fetch explicit friends from friends collection
        dispatchGroup.enter()
        fetchExplicitFriends(currentUserID: currentUserID) { explicitFriends in
            allFriends.append(contentsOf: explicitFriends)
            dispatchGroup.leave()
        }
        
        // Step 2: Fetch all group members as implicit friends
        dispatchGroup.enter()
        fetchGroupMembers(currentUserID: currentUserID) { groupMembers in
            // Combine with explicit friends, removing any duplicates
            let existingEmails = Set(allFriends.map { $0.email })
            let newFriends = groupMembers.filter { !existingEmails.contains($0.email) }
            allFriends.append(contentsOf: newFriends)
            dispatchGroup.leave()
        }
        
        // Step 3: Calculate balances for all friends
        dispatchGroup.notify(queue: .main) {
            self.calculateBalances(currentUserID: currentUserID, friends: allFriends) { friendsWithBalances in
                DispatchQueue.main.async {
                    self.friends = friendsWithBalances
                    self.isLoading = false
                }
            }
        }
    }
    
    // Fetch explicit friends from the friends collection
    private func fetchExplicitFriends(currentUserID: String, completion: @escaping ([Friend]) -> Void) {
        var friends: [Friend] = []
        
        db.collection("users").document(currentUserID).collection("friends").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                completion([])
                return
            }
            
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let group = DispatchGroup()
            
            for doc in snapshot?.documents ?? [] {
                let friendID = doc.documentID
                
                group.enter()
                self.fetchUserProfile(userID: friendID) { friend in
                    if let friend = friend {
                        friends.append(friend)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .global()) {
                completion(friends)
            }
        }
    }
    
    // Fetch all members from all groups the user is part of
    private func fetchGroupMembers(currentUserID: String, completion: @escaping ([Friend]) -> Void) {
        var groupMembers: [Friend] = []
        var processedMemberIDs = Set<String>()
        
        // Add current user to processed IDs to exclude them
        processedMemberIDs.insert(currentUserID)
        
        db.collection("Group")
            .whereField("members", arrayContains: currentUserID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion([])
                    return
                }
                
                if let error = error {
                    print("Error fetching groups: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let group = DispatchGroup()
                
                for groupDoc in snapshot?.documents ?? [] {
                    if let members = groupDoc.data()["members"] as? [String] {
                        for memberID in members {
                            // Skip current user and already processed members
                            if memberID == currentUserID || processedMemberIDs.contains(memberID) {
                                continue
                            }
                            
                            processedMemberIDs.insert(memberID)
                            
                            group.enter()
                            self.fetchUserProfile(userID: memberID) { friend in
                                if let friend = friend {
                                    // Add the group name to the friend object
                                    var friendWithGroup = friend
                                    friendWithGroup.groupName = groupDoc.data()["name"] as? String ?? "Unknown Group"
                                    groupMembers.append(friendWithGroup)
                                }
                                group.leave()
                            }
                        }
                    }
                }
                
                group.notify(queue: .global()) {
                    completion(groupMembers)
                }
            }
    }
    
    // Fetch user profile by ID
    private func fetchUserProfile(userID: String, completion: @escaping (Friend?) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user details: \(error)")
                completion(nil)
                return
            }
            
            guard let userData = snapshot?.data(),
                  let firstName = userData["firstName"] as? String,
                  let lastName = userData["lastName"] as? String,
                  let email = userData["email"] as? String else {
                completion(nil)
                return
            }
            
            let friend = Friend(
                id: userID,
                name: "\(firstName) \(lastName)",
                email: email,
                imageURL: userData["profileImageURL"] as? String,
                amountOwed: 0
            )
            
            completion(friend)
        }
    }
    
    // Calculate balances for all friends
    private func calculateBalances(currentUserID: String, friends: [Friend], completion: @escaping ([Friend]) -> Void) {
        var updatedFriends = friends
        let group = DispatchGroup()
        
        // Query all balances where user is involved
        db.collection("balances")
            .whereField("users", arrayContains: currentUserID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching balances: \(error)")
                    completion(updatedFriends)
                    return
                }
                
                for balanceDoc in snapshot?.documents ?? [] {
                    let balanceData = balanceDoc.data()
                    
                    guard let users = balanceData["users"] as? [String],
                          let amounts = balanceData["amounts"] as? [String: Double] else {
                        continue
                    }
                    
                    // Find the other user(s) in this balance document
                    for userID in users where userID != currentUserID {
                        // Find friend in our list
                        if let index = updatedFriends.firstIndex(where: { $0.id == userID }) {
                            let currentUserAmount = amounts[currentUserID] ?? 0
                            let friendAmount = amounts[userID] ?? 0
                            
                            // Calculate net amount
                            // Positive means friend owes user, negative means user owes friend
                            let netAmount = friendAmount - currentUserAmount
                            
                            // Update friend's amount
                            updatedFriends[index].amountOwed += netAmount
                        }
                    }
                }
                
                completion(updatedFriends)
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
        
        // Get the friend's user ID
        let friendID = friend.id
        
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
