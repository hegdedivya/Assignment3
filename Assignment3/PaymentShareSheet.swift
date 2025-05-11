//
//  PaymentShareSheet.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct PaymentShareSheet: View {
    var friend: Friend
    var amount: Double
    var note: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Payment Request")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "qrcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    PaymentDetailRow(title: "Amount", value: "$\(String(format: "%.2f", abs(amount)))")
                    PaymentDetailRow(title: "To", value: friend.name)
                    
                    if !note.isEmpty {
                        PaymentDetailRow(title: "Note", value: note)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                HStack(spacing: 15) {
                    ShareButton(title: "Text", icon: "message.fill", color: .green) {
                        // Share via text
                    }
                    
                    ShareButton(title: "Email", icon: "envelope.fill", color: .blue) {
                        // Share via email
                    }
                    
                    ShareButton(title: "Copy", icon: "doc.on.doc", color: .orange) {
                        // Copy payment details
                        UIPasteboard.general.string = "Payment request to \(friend.name) for $\(String(format: "%.2f", abs(amount)))\(note.isEmpty ? "" : " - \(note)")"
                    }
                    
                    ShareButton(title: "More", icon: "square.and.arrow.up", color: .gray) {
                        // Show system share sheet
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct ShareButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct PaymentDetailRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct PaymentShareSheet_Previews: PreviewProvider {
    static var previews: some View {
        PaymentShareSheet(
            friend: Friend(id: "1", name: "John Doe", email: "john@example.com"),
            amount: 25.0,
            note: "Dinner last night"
        )
    }
}
