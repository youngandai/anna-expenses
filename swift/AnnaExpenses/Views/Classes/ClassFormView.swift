import SwiftUI

struct ClassFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var studentID: UUID?
    @State private var teacherID: UUID?
    @State private var packageID: UUID?
    @State private var date = Date()
    @State private var notes = ""

    private var availablePackages: [Package] {
        guard let sid = studentID else { return [] }
        return store.packages(for: sid)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Record Class Session")
                .font(.title2.bold())

            Form {
                Picker("Student", selection: $studentID) {
                    Text("Select Student").tag(UUID?.none)
                    ForEach(store.students.sorted { $0.name < $1.name }) { student in
                        Text(student.name).tag(UUID?.some(student.id))
                    }
                }
                .onChange(of: studentID) { _, _ in packageID = nil }

                Picker("Teacher", selection: $teacherID) {
                    Text("Select Teacher").tag(UUID?.none)
                    ForEach(store.teachers.sorted { $0.name < $1.name }) { teacher in
                        Text(teacher.name).tag(UUID?.some(teacher.id))
                    }
                }

                Picker("Package", selection: $packageID) {
                    Text("Select Package").tag(UUID?.none)
                    ForEach(availablePackages) { pkg in
                        let used = store.classesUsed(for: pkg.id)
                        Text("\(pkg.name) (\(used)/\(pkg.totalClasses))").tag(UUID?.some(pkg.id))
                    }
                }

                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    guard let sid = studentID, let tid = teacherID, let pid = packageID else { return }
                    let session = ClassSession(
                        packageID: pid,
                        studentID: sid,
                        teacherID: tid,
                        date: date,
                        notes: notes.isEmpty ? nil : notes
                    )
                    store.sessions.append(session)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(studentID == nil || teacherID == nil || packageID == nil)
            }
            .padding()
        }
        .frame(width: 450, height: 380)
    }
}
