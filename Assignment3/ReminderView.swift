//
//  RemindersView.swift
//  Assignment3
//
//
 
import SwiftUI
 
struct RemindersView: View {
    @State private var reminders: [ReminderNotification] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading reminders...")
                } else if reminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No reminders")
                            .font(.headline)
                        
                        Text("You don't have any payment reminders")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(reminders) { reminder in
                            ReminderRowView(reminder: reminder) {
                                // Mark as read
                                NotificationManager.shared.markReminderAsRead(reminderID: reminder.id) { success in
                                    if success {
                                        fetchReminders()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .onAppear {
                fetchReminders()
            }
            .refreshable {
                fetchReminders()
            }
        }
    }
    
    private func fetchReminders() {
        isLoading = true
        NotificationManager.shared.fetchReminders { fetchedReminders in
            DispatchQueue.main.async {
                self.reminders = fetchedReminders
                self.isLoading = false
            }
        }
    }
}
 
struct ReminderRowView: View {
    let reminder: ReminderNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.message)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    if let groupName = reminder.groupName {
                        Text("in \(groupName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(reminder.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("$\(String(format: "%.2f", reminder.amount))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
 
struct RemindersView_Previews: PreviewProvider {
    static var previews: some View {
        RemindersView()
    }
}
