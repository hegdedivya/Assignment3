//
//  PaymentView.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct PaymentView: View {
    var friend: Friend
    var amount: Double
    
    @StateObject private var viewModel = PaymentViewModel()
    @State private var showingConfirmation = false
    @State private var showShareOptions = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Payment amount
                    VStack(spacing: 8) {
                        Text("Paying")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            // Avatar
                            Circle()
                                .fill(Color.teal.opacity(0.8))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(friend.name.prefix(1).uppercased()))
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                )
                            
                            Text(friend.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Text("$\(String(format: "%.2f", abs(amount)))")
                            .font(.system(size: 48, weight: .bold))
                            .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a note")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g. Dinner payment", text: $viewModel.paymentNote)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Payment methods
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose payment method")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(PaymentMethod.allMethods) { method in
                                Button(action: {
                                    viewModel.selectedPaymentMethod = method
                                }) {
                                    HStack {
                                        Image(systemName: method.icon)
                                            .foregroundColor(method.color)
                                            .font(.system(size: 18))
                                        
                                        Text(method.name)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        if viewModel.selectedPaymentMethod?.id == method.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                viewModel.selectedPaymentMethod?.id == method.id ? method.color : Color.gray.opacity(0.3),
                                                lineWidth: viewModel.selectedPaymentMethod?.id == method.id ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }
                    
                    // Payment button
                    Button(action: {
                        if viewModel.selectedPaymentMethod != nil {
                            showingConfirmation = true
                        } else {
                            viewModel.errorMessage = "Please select a payment method"
                        }
                    }) {
                        HStack {
                            Text("Confirm Payment")
                            
                            if viewModel.isProcessing {
                                ProgressView()
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.selectedPaymentMethod != nil ? Color.orange : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(viewModel.selectedPaymentMethod == nil || viewModel.isProcessing)
                    
                    // Share QR code option
                    Button(action: {
                        showShareOptions = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Payment Info")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Payment")
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
                    title: Text("Confirm Payment"),
                    message: Text("Are you sure you want to pay $\(String(format: "%.2f", abs(amount))) to \(friend.name)?"),
                    primaryButton: .default(Text("Confirm")) {
                        processPayment()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .sheet(isPresented: $showShareOptions) {
                PaymentShareSheet(friend: friend, amount: amount, note: viewModel.paymentNote)
            }
            .alert(isPresented: $viewModel.paymentCompleted) {
                Alert(
                    title: Text("Payment Successful"),
                    message: Text("You have successfully paid $\(String(format: "%.2f", abs(amount))) to \(friend.name)"),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
    
    func processPayment() {
        viewModel.processPayment(to: friend, amount: amount) { success in
            // If success is false, the error message will be set in the viewModel
        }
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(
            friend: Friend(id: "1", name: "John Doe", email: "john@example.com", amountOwed: 25.0),
            amount: 25.0
        )
    }
}
