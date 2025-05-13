//
//  SettleUpView.swift
//  Assignment3
//

//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SettleUpView: View {
    let friend: Friend?
    let group: Group?
    let amount: Double
    let isUserOwing: Bool // true if user owes, false if user is owed
    
    @StateObject private var viewModel = SettleUpViewModel()
    @State private var showingConfirmation = false
    @State private var showingPaymentSheet = false
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var settlementNote = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    if let friend = friend {
                        Text("Settle with \(friend.name)")
                            .font(.title2)
                            .fontWeight(.bold)
                    } else if let group = group {
                        Text("Settle up in \(group.name)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    VStack(spacing: 4) {
                        Text(isUserOwing ? "You owe" : "You are owed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("$\(String(format: "%.2f", abs(amount)))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(isUserOwing ? .orange : .green)
                    }
                }
                
                // Settlement note
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a note (optional)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g. Payment for dinner", text: $settlementNote)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Payment method selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment method")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(PaymentMethod.allMethods) { method in
                            Button(action: {
                                selectedPaymentMethod = method
                            }) {
                                HStack {
                                    Image(systemName: method.icon)
                                        .foregroundColor(method.color)
                                        .font(.system(size: 18))
                                    
                                    Text(method.name)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    if selectedPaymentMethod?.id == method.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedPaymentMethod?.id == method.id ? method.color : Color.gray.opacity(0.3),
                                            lineWidth: selectedPaymentMethod?.id == method.id ? 2 : 1
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Error message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if isUserOwing {
                        // User owes money - show payment button
                        Button(action: {
                            if selectedPaymentMethod != nil {
                                showingPaymentSheet = true
                            } else {
                                viewModel.errorMessage = "Please select a payment method"
                            }
                        }) {
                            HStack {
                                Text("Pay $\(String(format: "%.2f", abs(amount)))")
                                
                                if viewModel.isProcessing {
                                    ProgressView()
                                        .padding(.leading, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPaymentMethod != nil ? Color.orange : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(selectedPaymentMethod == nil || viewModel.isProcessing)
                    } else {
                        // User is owed money - show record payment button
                        Button(action: {
                            if selectedPaymentMethod != nil {
                                showingConfirmation = true
                            } else {
                                viewModel.errorMessage = "Please select a payment method"
                            }
                        }) {
                            Text("Record Payment Received")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedPaymentMethod != nil ? Color.green : Color.gray.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(selectedPaymentMethod == nil)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Record Payment"),
                    message: Text("Mark this payment as received from \(friend?.name ?? "group members")?"),
                    primaryButton: .default(Text("Record")) {
                        recordPayment()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingPaymentSheet) {
                if isUserOwing {
                    if let friend = friend {
                        PaymentView(friend: friend, amount: amount)
                    } else {
                        // For group settlements, we'd need a different payment view
                        // For now, let's handle it as a simple transaction
                        Text("Group payment not yet implemented")
                    }
                }
            }
            .onChange(of: viewModel.settlementCompleted) { completed in
                if completed {
                    dismiss()
                }
            }
        }
    }
    
    private func recordPayment() {
        guard let selectedPaymentMethod = selectedPaymentMethod else { return }
        
        if let friend = friend {
            viewModel.recordFriendPayment(
                friend: friend,
                amount: amount,
                paymentMethod: selectedPaymentMethod,
                note: settlementNote
            )
        } else if let group = group {
            viewModel.recordGroupPayment(
                group: group,
                amount: amount,
                paymentMethod: selectedPaymentMethod,
                note: settlementNote
            )
        }
    }
}
