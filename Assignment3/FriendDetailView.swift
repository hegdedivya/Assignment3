//
//  FriendDetailView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct FriendDetailView: View {
    var friend: Friend
    @StateObject private var viewModel = FriendViewModel()
    @State private var showingPaymentSheet = false
    @State private var showingAddExpenseSheet = false
    
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
                
                HStack(spacing: 20) {
                    if friend.amountOwed != 0 {
                        Button(action: {
                            showingPaymentSheet = true
                        }) {
                            Text("Settle up")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.orange)
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
            AddExpenseView(friend: friend)
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
