import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Friend: Identifiable {
    var id = UUID()
    var name: String
    var email: String
    var imageURL: String?
    var amountOwed: Double // Positive means friend owes you, negative means you owe friend
}

struct FriendView: View {
    @State private var friends: [Friend] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    List {
                        ForEach(filteredFriends) { friend in
                            NavigationLink(destination: FriendDetailView(friend: friend)) {
                                HStack {
                                    // Avatar
                                    if let imageURL = friend.imageURL, !imageURL.isEmpty {
                                        AsyncImage(url: URL(string: imageURL)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.teal.opacity(0.8))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text(String(friend.name.prefix(1).uppercased()))
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20, weight: .bold))
                                            )
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(friend.name)
                                            .font(.headline)
                                        
                                        if friend.amountOwed > 0 {
                                            Text("\(friend.name) owes you $\(String(format: "%.2f", friend.amountOwed))")
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                        } else if friend.amountOwed < 0 {
                                            Text("You owe \(friend.name) $\(String(format: "%.2f", abs(friend.amountOwed)))")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                        } else {
                                            Text("All settled up")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        if friend.amountOwed != 0 {
                                            Button(action: {
                                                // Settle up button action
                                                showPaymentView(for: friend)
                                            }) {
                                                Text("Settle up")
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.orange)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search friends")
                    .listStyle(PlainListStyle())
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
                AddFriendView(onFriendAdded: { newFriend in
                    friends.append(newFriend)
                })
            }
            .onAppear {
                fetchFriends()
            }
        }
    }
    
    func fetchFriends() {
        isLoading = true
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Get current user's friend list
        db.collection("users").document(currentUserID).collection("friends").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching friends: \(error)")
                isLoading = false
                return
            }
            
            var tempFriends: [Friend] = []
            
            guard let documents = snapshot?.documents else {
                isLoading = false
                return
            }
            
            let group = DispatchGroup()
            
            for doc in documents {
                let data = doc.data()
                let friendID = doc.documentID
                
                group.enter()
                
                // Get friend's user information
                db.collection("users").document(friendID).getDocument { userSnapshot, userError in
                    defer { group.leave() }
                    
                    if let userError = userError {
                        print("❌ Error fetching user details: \(userError)")
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
                    db.collection("balances")
                        .whereField("users", arrayContains: currentUserID)
                        .getDocuments { balanceSnapshot, balanceError in
                            defer { group.leave() }
                            
                            if let balanceError = balanceError {
                                print("❌ Error fetching balances: \(balanceError)")
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
    
    func showPaymentView(for friend: Friend) {
        // Add navigation to payment page logic here
        print("Navigate to payment page for friend: \(friend.name)")
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchEmail = ""
    @State private var searchResults: [Friend] = []
    @State private var isSearching = false
    @State private var errorMessage = ""
    
    var onFriendAdded: (Friend) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter email to search for users", text: $searchEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                
                Button("Search") {
                    searchUser()
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        ForEach(searchResults) { user in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button("Add") {
                                    addFriend(user)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    func searchUser() {
        guard !searchEmail.isEmpty else {
            errorMessage = "Please enter an email address"
            return
        }
        
        isSearching = true
        errorMessage = ""
        searchResults = []
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("email", isEqualTo: searchEmail)
            .getDocuments { snapshot, error in
                isSearching = false
                
                if let error = error {
                    errorMessage = "Search error: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    errorMessage = "User not found"
                    return
                }
                
                for doc in documents {
                    let data = doc.data()
                    guard let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let email = data["email"] as? String else {
                        continue
                    }
                    
                    let friend = Friend(
                        name: "\(firstName) \(lastName)",
                        email: email,
                        imageURL: data["profileImageURL"] as? String,
                        amountOwed: 0
                    )
                    
                    searchResults.append(friend)
                }
            }
    }
    
    func addFriend(_ friend: Friend) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in"
            return
        }
        
        let db = Firestore.firestore()
        
        // Get the UID of the friend to add
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to add friend: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    errorMessage = "User not found"
                    return
                }
                
                // Add friend to current user's friend list
                db.collection("users").document(currentUserID).collection("friends").document(friendID).setData([
                    "addedAt": Timestamp()
                ]) { error in
                    if let error = error {
                        errorMessage = "Failed to add friend: \(error.localizedDescription)"
                        return
                    }
                    
                    // Add current user to friend's friend list (reciprocal)
                    db.collection("users").document(friendID).collection("friends").document(currentUserID).setData([
                        "addedAt": Timestamp()
                    ]) { error in
                        if let error = error {
                            errorMessage = "Failed to add friend: \(error.localizedDescription)"
                            return
                        }
                        
                        // Successfully added friend
                        onFriendAdded(friend)
                        dismiss()
                    }
                }
            }
    }
}

struct FriendDetailView: View {
    var friend: Friend
    @State private var activities: [Activity] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            // Friend profile card
            VStack(spacing: 10) {
                if let imageURL = friend.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.teal.opacity(0.8))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(friend.name.prefix(1).uppercased()))
                                .foregroundColor(.white)
                                .font(.system(size: 36, weight: .bold))
                        )
                }
                
                Text(friend.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
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
                
                if friend.amountOwed != 0 {
                    Button(action: {
                        // Settle up button action
                    }) {
                        Text("Settle up")
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
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
                
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if activities.isEmpty {
                    Text("No shared activities")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(activities) { activity in
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
            fetchSharedActivities()
        }
    }
    
    func fetchSharedActivities() {
        // Fetch shared activities with this friend from Firebase
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // First get the friend's userID
        db.collection("users")
            .whereField("email", isEqualTo: friend.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error finding friend: \(error)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty,
                      let friendID = documents[0].documentID as String? else {
                    isLoading = false
                    return
                }
                
                // Query activities that both users are part of
                db.collection("activities")
                    .whereField("members", arrayContains: currentUserID)
                    .getDocuments { activitySnapshot, activityError in
                        if let activityError = activityError {
                            print("❌ Error fetching activities: \(activityError)")
                            isLoading = false
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
                            self.activities = sharedActivities
                            self.isLoading = false
                        }
                    }
            }
    }
}

#Preview {
    FriendView()
}
