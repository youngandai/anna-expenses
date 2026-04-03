import SwiftUI
import UniformTypeIdentifiers

struct RateBulkImportView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var importResult: String?
    @State private var importedCount = 0
    @State private var previewRates: [(teacherName: String, subject: String, duration: Int, amount: Double, currency: String)] = []
    @State private var csvContent: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Bulk Import Teacher Rates")
                .font(.title2.bold())

            GroupBox {
                VStack(spacing: 12) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("CSV format: teacher_name, subject, duration_minutes, amount, currency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Example:\nAnna, English, 60, 2000, RUB\nAnna, Exam Prep, 30, 1500, RUB")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)

                    Button("Select CSV File") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }

            if !previewRates.isEmpty {
                GroupBox("Preview (\(previewRates.count) rates)") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(previewRates.indices, id: \.self) { idx in
                                let r = previewRates[idx]
                                HStack {
                                    Text(r.teacherName)
                                        .frame(width: 100, alignment: .leading)
                                    Text(r.subject)
                                        .frame(width: 100, alignment: .leading)
                                    Text("\(r.duration)min")
                                        .frame(width: 50)
                                    Spacer()
                                    Text(String(format: "%.0f %@", r.amount, r.currency))
                                        .monospacedDigit()
                                }
                                .font(.caption)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }

                Button("Import \(previewRates.count) Rates") {
                    performImport()
                }
                .buttonStyle(.borderedProminent)
            }

            if let result = importResult {
                GroupBox {
                    HStack {
                        Image(systemName: importedCount > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(importedCount > 0 ? .green : .orange)
                        Text(result)
                    }
                    .padding(4)
                }
            }

            Spacer()

            HStack {
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 550, height: 500)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelected(result)
        }
    }

    private func handleFileSelected(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importResult = "Could not access the file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                csvContent = content
                previewRates = parseRatesCSV(content)
                if previewRates.isEmpty {
                    importResult = "No valid rates found in file"
                } else {
                    importResult = nil
                }
            } catch {
                importResult = "Error reading file: \(error.localizedDescription)"
            }

        case .failure(let error):
            importResult = "Error: \(error.localizedDescription)"
        }
    }

    private func parseRatesCSV(_ content: String) -> [(teacherName: String, subject: String, duration: Int, amount: Double, currency: String)] {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard lines.count > 1 else { return [] }

        var results: [(teacherName: String, subject: String, duration: Int, amount: Double, currency: String)] = []

        for line in lines.dropFirst() {
            let cols = CSVImporter.parseLine(line)
            guard cols.count >= 5 else { continue }

            let name = cols[0].trimmingCharacters(in: .whitespaces)
            let subject = cols[1].trimmingCharacters(in: .whitespaces)
            let durationStr = cols[2].trimmingCharacters(in: .whitespaces)
            let amountStr = cols[3].trimmingCharacters(in: .whitespaces)
            let currency = cols[4].trimmingCharacters(in: .whitespaces).uppercased()

            guard let duration = Int(durationStr), let amount = Double(amountStr) else { continue }
            results.append((teacherName: name, subject: subject, duration: duration, amount: amount, currency: currency))
        }

        return results
    }

    private func performImport() {
        var matched = 0
        var unmatched = 0

        for entry in previewRates {
            let teacher = store.teachers.first {
                $0.name.localizedCaseInsensitiveContains(entry.teacherName) ||
                entry.teacherName.localizedCaseInsensitiveContains($0.name)
            }

            if let teacher {
                let rate = Rate(
                    teacherID: teacher.id,
                    amount: entry.amount,
                    currency: entry.currency,
                    durationMinutes: entry.duration,
                    subject: entry.subject
                )
                store.rates.append(rate)
                matched += 1
            } else {
                unmatched += 1
            }
        }

        store.save()
        importedCount = matched
        importResult = "Imported \(matched) rates" + (unmatched > 0 ? ", \(unmatched) skipped (teacher not found)" : "")
        previewRates = []
    }
}
