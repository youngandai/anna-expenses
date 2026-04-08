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
            .help("New Item (Cmd+N)")
        }
        .sheet(isPresented: $showingAddSheet) {
            TeacherFormView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
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
        RecordSheetContainer(title: "Add Teacher", width: 440) {
            RecordSheetCard {
                formRow("Name") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                formRow("Email") {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                formRow("Payment Details") {
                    TextField("Payment Details", text: $paymentDetails, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
            }
        } actions: {
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
        }
    }

    @ViewBuilder
    private func formRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(label)
                .frame(width: 150, alignment: .leading)

            content()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
