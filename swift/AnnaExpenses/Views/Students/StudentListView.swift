import SwiftUI

struct StudentListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false
    @State private var selectedStudent: Student?
    @State private var searchText = ""

    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return store.students.sorted { $0.name < $1.name }
        }
        return store.students.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List(selection: $selectedStudent) {
            ForEach(filteredStudents) { student in
                HStack {
                    VStack(alignment: .leading) {
                        Text(student.name)
                            .font(.headline)
                        if let email = student.email, !email.isEmpty {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    let pkgCount = store.packages(for: student.id).count
                    if pkgCount > 0 {
                        Text("\(pkgCount) packages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(student)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if let idx = store.students.firstIndex(where: { $0.id == student.id }) {
                            store.students.remove(at: idx)
                            store.save()
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search students")
        .navigationTitle("Students")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add Student", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            StudentFormView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
        }
    }
}

struct StudentFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Student")
                .font(.title2.bold())

            Form {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let student = Student(
                        name: name,
                        email: email.isEmpty ? nil : email,
                        phone: phone.isEmpty ? nil : phone,
                        notes: notes.isEmpty ? nil : notes
                    )
                    store.students.append(student)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}
