import SwiftUI

struct ClassFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var studentID: UUID?
    @State private var teacherID: UUID?
    @State private var packageID: UUID?
    @State private var date = Date()
    @State private var durationMinutes = 60
    @State private var notes = ""

    private let durations = [30, 45, 60, 90, 120]

    private var availablePackages: [Package] {
        guard let sid = studentID else { return [] }
        return store.packages(for: sid)
    }

    var body: some View {
        RecordSheetContainer(title: "Record Class Session", width: 520) {
            RecordSheetCard {
                formRow("Student") {
                    Picker("", selection: $studentID) {
                        Text("Select Student").tag(UUID?.none)
                        ForEach(store.students.sorted { $0.name < $1.name }) { student in
                            Text(student.name).tag(UUID?.some(student.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200, alignment: .trailing)
                }
                .onChange(of: studentID) { _, _ in packageID = nil }

                Divider()

                formRow("Teacher") {
                    Picker("", selection: $teacherID) {
                        Text("Select Teacher").tag(UUID?.none)
                        ForEach(store.teachers.sorted { $0.name < $1.name }) { teacher in
                            Text(teacher.name).tag(UUID?.some(teacher.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200, alignment: .trailing)
                }

                Divider()

                formRow("Package") {
                    Picker("", selection: $packageID) {
                        Text("Select Package").tag(UUID?.none)
                        ForEach(availablePackages) { pkg in
                            let used = store.classesUsed(for: pkg.id)
                            Text("\(pkg.name) (\(used)/\(pkg.totalClasses))").tag(UUID?.some(pkg.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220, alignment: .trailing)
                }

                Divider()

                formRow("Date") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 140, alignment: .trailing)
                }

                Divider()

                formRow("Duration") {
                    Picker("", selection: $durationMinutes) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d) min").tag(d)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120, alignment: .trailing)
                }

                Divider()

                formRow("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
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
                    guard let sid = studentID, let tid = teacherID, let pid = packageID else { return }
                    let session = ClassSession(
                        packageID: pid,
                        studentID: sid,
                        teacherID: tid,
                        date: date,
                        durationMinutes: durationMinutes,
                        notes: notes.isEmpty ? nil : notes
                    )
                    store.sessions.append(session)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(studentID == nil || teacherID == nil || packageID == nil)
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
