//
//  GroupDetailsView.swift
//  Assignment3
//
//  Created by Divya on 6/5/2025.
//

import SwiftUI

struct GroupDetailView: View {
    var group: Group
    @State private var isAddUserPresented: Bool = false

    var body: some View {
        VStack {
            Text(group.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Members")
                .font(.headline)
                .padding(.top)

            List(group.members, id: \.self) { memberId in
                Text(memberId) // Replace with actual user name if needed
            }

            Spacer()

            // Add User Button
            Button(action: {
                isAddUserPresented = true
            }) {
                Text("Add User")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $isAddUserPresented) {
                AddUserToGroupView(group: group)
            }
        }
        .padding()
        .navigationTitle(group.name)
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GroupDetailView(group: Group(id: "1", name: "Trip to Bali", members: ["John", "Jane"], createdAt: Date()))
    }
}
