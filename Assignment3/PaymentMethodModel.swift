//
//  PaymentMethodModel.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import SwiftUI

struct PaymentMethod: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var icon: String
    var color: Color
    
    static let cash = PaymentMethod(name: "Cash", icon: "banknote", color: .green)
    static let bankTransfer = PaymentMethod(name: "Bank Transfer", icon: "arrow.left.arrow.right", color: .blue)
    static let paypal = PaymentMethod(name: "PayPal", icon: "p.circle.fill", color: .blue)
    static let googlePay = PaymentMethod(name: "Google Pay", icon: "g.circle.fill", color: .red)
    
    static let allMethods = [cash, bankTransfer, paypal, googlePay]
    
    static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        return lhs.id == rhs.id
    }
}
