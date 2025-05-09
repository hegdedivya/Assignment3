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
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return viewModel.friends
        } else {
            return viewModel.friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
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
                                                selectedFriend = friend
                                                navigateToPayment = true
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
            .onAppear {
                viewModel.fetchFriends()
            }
        }
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView()
    }
}
