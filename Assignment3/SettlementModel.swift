//
//  SettlementModel.swift
//  Assignment3
//
//  Created by Minkun He on 9/5/2025.
//

import Foundation
import FirebaseFirestore

struct Settlement: Identifiable, Codable {
    var id: String
    var amount: Double
    var fromUserID: String
    var toUserID: String
    var date: Date
    var method: String
    var note: String
    var status: SettlementStatus
    
    enum SettlementStatus: String, Codable {
        case pending = "pending"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    // Custom init for creating a new settlement (ID will be assigned by Firestore)
    init(amount: Double, fromUserID: String, toUserID: String, method: String, note: String, status: SettlementStatus = .completed) {
        self.id = UUID().uuidString
        self.amount = amount
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.date = Date()
        self.method = method
        self.note = note
        self.status = status
    }
    
    // Init with ID (used when fetching from Firestore)
    init(id: String, amount: Double, fromUserID: String, toUserID: String, date: Date, method: String, note: String, status: SettlementStatus) {
        self.id = id
        self.amount = amount
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.date = date
        self.method = method
        self.note = note
        self.status = status
    }
    
    // Convert Firestore document to Settlement
    static func fromFirestore(document: DocumentSnapshot) -> Settlement? {
        guard let data = document.data(),
              let amount = data["amount"] as? Double,
              let fromUserID = data["from"] as? String,
              let toUserID = data["to"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let method = data["method"] as? String,
              let statusString = data["status"] as? String,
              let status = SettlementStatus(rawValue: statusString) else {
            return nil
        }
        
        let note = data["note"] as? String ?? ""
        let date = timestamp.dateValue()
        
        return Settlement(
            id: document.documentID,
            amount: amount,
            fromUserID: fromUserID,
            toUserID: toUserID,
            date: date,
            method: method,
            note: note,
            status: status
        )
    }
    
    // Convert Settlement to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "amount": amount,
            "from": fromUserID,
            "to": toUserID,
            "date": Timestamp(date: date),
            "method": method,
            "note": note,
            "status": status.rawValue
        ]
    }
}
