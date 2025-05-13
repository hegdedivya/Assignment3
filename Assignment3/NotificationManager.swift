//
//  NotificationManager.swift
//  Assignment3
//
//  Created by Minkun He on 13/5/2025.
//
 
import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
 
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Request permission for notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            } else {
                print("Notification permission granted: \(success)")
            }
        }
    }
    
    // Send a reminder to a friend
    func sendReminder(to friend: Friend, amount: Double, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(false, "You must be logged in to send reminders")
            return
        }
        
        // Get current user's name first
        db.collection("users").document(currentUserID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, "Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            let userData = snapshot?.data()
            let senderFirstName = userData?["firstName"] as? String ?? "Someone"
            let senderLastName = userData?["lastName"] as? String ?? ""
            let senderName = "\(senderFirstName) \(senderLastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create reminder document
            let reminderData: [String: Any] = [
                "from": currentUserID,
                "to": friend.id,
                "amount": amount,
                "message": "Reminder: You owe \(senderName) $\(String(format: "%.2f", amount))",
                "timestamp": Timestamp(),
                "type": "payment_reminder",
                "status": "sent"
            ]
            
            // Save reminder to Firestore
            self.db.collection("notifications").addDocument(data: reminderData) { error in
                if let error = error {
                    completion(false, "Error sending reminder: \(error.localizedDescription)")
                    return
                }
                
                // In a real app, you would also send a push notification here
                // For now, we'll simulate it with a local notification
                self.createLocalNotification(
                    title: "Reminder Sent",
                    body: "Your reminder has been sent to \(friend.name)"
                )
                
                completion(true, nil)
            }
        }
    }
    
    // Send a reminder in a group context
    func sendGroupReminder(to memberID: String, memberName: String, group: Group, amount: Double, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(false, "You must be logged in to send reminders")
            return
        }
        
        // Get current user's name first
        db.collection("users").document(currentUserID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, "Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            let userData = snapshot?.data()
            let senderFirstName = userData?["firstName"] as? String ?? "Someone"
            let senderLastName = userData?["lastName"] as? String ?? ""
            let senderName = "\(senderFirstName) \(senderLastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create group reminder document
            let reminderData: [String: Any] = [
                "from": currentUserID,
                "to": memberID,
                "groupID": group.id ?? "",
                "groupName": group.name,
                "amount": amount,
                "message": "Reminder from \(group.name): You owe \(senderName) $\(String(format: "%.2f", amount))",
                "timestamp": Timestamp(),
                "type": "group_payment_reminder",
                "status": "sent"
            ]
            
            // Save reminder to Firestore
            self.db.collection("notifications").addDocument(data: reminderData) { error in
                if let error = error {
                    completion(false, "Error sending reminder: \(error.localizedDescription)")
                    return
                }
                
                // Create local notification
                self.createLocalNotification(
                    title: "Group Reminder Sent",
                    body: "Your reminder has been sent to \(memberName) in \(group.name)"
                )
                
                completion(true, nil)
            }
        }
    }
    
    // Get reminders for the current user
    func fetchReminders(completion: @escaping ([ReminderNotification]) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection("notifications")
            .whereField("to", isEqualTo: currentUserID)
            .whereField("type", in: ["payment_reminder", "group_payment_reminder"])
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reminders: \(error)")
                    completion([])
                    return
                }
                
                var reminders: [ReminderNotification] = []
                
                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    
                    if let from = data["from"] as? String,
                       let amount = data["amount"] as? Double,
                       let message = data["message"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp,
                       let type = data["type"] as? String {
                        
                        let groupID = data["groupID"] as? String
                        let groupName = data["groupName"] as? String
                        
                        let reminder = ReminderNotification(
                            id: doc.documentID,
                            from: from,
                            amount: amount,
                            message: message,
                            timestamp: timestamp.dateValue(),
                            type: type,
                            groupID: groupID,
                            groupName: groupName
                        )
                        
                        reminders.append(reminder)
                    }
                }
                
                completion(reminders)
            }
    }
    
    // Mark reminder as read
    func markReminderAsRead(reminderID: String, completion: @escaping (Bool) -> Void) {
        db.collection("notifications").document(reminderID).updateData([
            "status": "read",
            "readAt": Timestamp()
        ]) { error in
            if let error = error {
                print("Error marking reminder as read: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Create local notification
    private func createLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            }
        }
    }
}
 
// Model for reminder notifications
struct ReminderNotification: Identifiable {
    let id: String
    let from: String
    let amount: Double
    let message: String
    let timestamp: Date
    let type: String
    let groupID: String?
    let groupName: String?
}
