import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(DataStore.self) private var store
    @State private var importType: ImportType = .transactions
    @State private var showingFilePicker = false
    @State private var importResult: String?
    @State private var importedCount = 0
    @State private var showingAIInstructions = false

    enum ImportType: String, CaseIterable {
        case transactions = "Bank Transactions"
        case attendance = "Attendance Records"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Import CSV Data")
                    .font(.title2.bold())

                Picker("Import Type", selection: $importType) {
                    ForEach(ImportType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 500)

                GroupBox {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text(formatDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Select CSV File") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .frame(width: 500)

                // AI Instructions panel
                GroupBox {
                    DisclosureGroup("AI Instructions", isExpanded: $showingAIInstructions) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Copy these instructions to your AI to reformat your data:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(aiInstructions)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Button("Copy to Clipboard") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(aiInstructions, forType: .string)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 8)
                    }
                    .padding(4)
                }
                .frame(width: 500)

                if let result = importResult {
                    GroupBox {
                        HStack {
                            Image(systemName: importedCount > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(importedCount > 0 ? .green : .orange)
                            Text(result)
                        }
                        .padding(4)
                    }
                    .frame(width: 500)
                }
            }
            .padding()
        }
        .navigationTitle("Import CSV")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private var formatDescription: String {
        switch importType {
        case .transactions:
            return "Expected columns: date, amount, description\nDate format: YYYY-MM-DD"
        case .attendance:
            return "Expected columns: date, student_name, teacher_name\nDate format: YYYY-MM-DD"
        }
    }

    private var aiInstructions: String {
        switch importType {
        case .transactions:
            return """
            Convert my data into a CSV file with exactly 3 columns and a header row.

            Header: date,amount,description
            - date: YYYY-MM-DD format
            - amount: number (positive for income, negative for expenses)
            - description: text, wrap in quotes if it contains commas

            Example:
            date,amount,description
            2025-03-15,5000,"Student payment, March"
            2025-03-16,-200,Office supplies
            """
        case .attendance:
            return """
            Convert my data into a CSV file with exactly 3 columns and a header row.

            Header: date,student_name,teacher_name
            - date: YYYY-MM-DD format
            - student_name: full name of the student
            - teacher_name: full name of the teacher

            Example:
            date,student_name,teacher_name
            2025-03-15,Maria Ivanova,Anna Smith
            2025-03-16,John Doe,Anna Smith
            """
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importResult = "Could not access the file"
                importedCount = 0
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)

                switch importType {
                case .transactions:
                    let transactions = try CSVImporter.parseTransactions(from: content)
                    store.transactions.append(contentsOf: transactions)
                    store.save()
                    importedCount = transactions.count
                    importResult = "Imported \(transactions.count) transactions"

                case .attendance:
                    let records = try CSVImporter.parseAttendance(from: content)
                    var matched = 0
                    var unmatched = 0

                    for record in records {
                        let student = store.students.first {
                            $0.name.localizedCaseInsensitiveContains(record.studentName) ||
                            record.studentName.localizedCaseInsensitiveContains($0.name)
                        }
                        let teacher = store.teachers.first {
                            $0.name.localizedCaseInsensitiveContains(record.teacherName) ||
                            record.teacherName.localizedCaseInsensitiveContains($0.name)
                        }

                        if let student, let teacher {
                            // Find the first available package for this student
                            if let pkg = store.packages(for: student.id).first(where: {
                                store.classesUsed(for: $0.id) < $0.totalClasses
                            }) {
                                let session = ClassSession(
                                    packageID: pkg.id,
                                    studentID: student.id,
                                    teacherID: teacher.id,
                                    date: record.date
                                )
                                store.sessions.append(session)
                                matched += 1
                            } else {
                                unmatched += 1
                            }
                        } else {
                            unmatched += 1
                        }
                    }
                    store.save()
                    importedCount = matched
                    importResult = "Matched \(matched) records, \(unmatched) unmatched (student/teacher not found or no available package)"
                }
            } catch {
                importResult = "Error: \(error.localizedDescription)"
                importedCount = 0
            }

        case .failure(let error):
            importResult = "Error: \(error.localizedDescription)"
            importedCount = 0
        }
    }
}
