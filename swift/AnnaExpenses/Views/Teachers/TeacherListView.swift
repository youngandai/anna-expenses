import SwiftUI

struct TeacherListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false
    @State private var searchText = ""

    private var filteredTeachers: [Teacher] {
        let sorted = store.teachers.sorted { $0.name < $1.name }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredTeachers) { teacher in
                HStack {
                    VStack(alignment: .leading) {
                        Text(teacher.name)
                            .font(.headline)
                        if let email = teacher.email, !email.isEmpty {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    let sessionCount = store.sessions.filter { $0.teacherID == teacher.id }.count
                    if sessionCount > 0 {
                        Text("\(sessionCount) classes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if let idx = store.teachers.firstIndex(where: { $0.id == teacher.id }) {
                            store.teachers.remove(at: idx)
                            store.save()
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search teachers")
        .navigationTitle("Teachers")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add Teacher", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            TeacherFormView()
        }
    }
}

struct TeacherFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var paymentDetails = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Teacher")
                .font(.title2.bold())

            Form {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                TextField("Payment Details", text: $paymentDetails, axis: .vertical)
                    .lineLimit(3)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let teacher = Teacher(
                        name: name,
                        email: email.isEmpty ? nil : email,
                        paymentDetails: paymentDetails.isEmpty ? nil : paymentDetails
                    )
                    store.teachers.append(teacher)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 250)
    }
}
