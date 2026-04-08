import SwiftUI

struct PackageListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false
    @State private var searchText = ""

    private var filteredPackages: [Package] {
        let sorted = store.packages.sorted { $0.purchaseDate > $1.purchaseDate }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            (store.student(for: $0.studentID)?.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredPackages) { pkg in
                HStack {
                    VStack(alignment: .leading) {
                        Text(pkg.name)
                            .font(.headline)
                        Text(store.student(for: pkg.studentID)?.name ?? "Unknown Student")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.2f %@", pkg.pricePaid, pkg.currency))
                            .font(.headline)
                        let used = store.classesUsed(for: pkg.id)
                        Text("\(used)/\(pkg.totalClasses) classes")
                            .font(.caption)
                            .foregroundStyle(used >= pkg.totalClasses ? .red : .secondary)
                    }
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if let idx = store.packages.firstIndex(where: { $0.id == pkg.id }) {
                            store.packages.remove(at: idx)
                            store.save()
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search packages")
        .navigationTitle("Packages")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add Package", systemImage: "plus")
            }
            .help("New Item (Cmd+N)")
        }
        .sheet(isPresented: $showingAddSheet) {
            PackageFormView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
        }
    }
}

struct PackageFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var studentID: UUID?
    @State private var totalClasses = 8
    @State private var pricePaid = ""
    @State private var currency = "AED"
    @State private var purchaseDate = Date()
    @State private var notes = ""

    var body: some View {
        RecordSheetContainer(title: "Add Package", width: 520) {
            RecordSheetCard {
                formRow("Package Name") {
                    TextField("Package Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

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

                Divider()

                formRow("Total Classes") {
                    Stepper(value: $totalClasses, in: 1...100) {
                        Text("\(totalClasses)")
                    }
                    .frame(width: 140, alignment: .trailing)
                }

                Divider()

                formRow("Price Paid") {
                    HStack(spacing: 10) {
                        TextField("Price Paid", text: $pricePaid)
                            .textFieldStyle(.roundedBorder)

                        Picker("Currency", selection: $currency) {
                            Text("AED").tag("AED")
                            Text("RUB").tag("RUB")
                            Text("USD").tag("USD")
                        }
                        .labelsHidden()
                        .frame(width: 92)
                    }
                }

                Divider()

                formRow("Purchase Date") {
                    DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 140, alignment: .trailing)
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
                    guard let sid = studentID, let price = Double(pricePaid) else { return }
                    let pkg = Package(
                        studentID: sid,
                        name: name,
                        totalClasses: totalClasses,
                        pricePaid: price,
                        currency: currency,
                        purchaseDate: purchaseDate,
                        notes: notes.isEmpty ? nil : notes
                    )
                    store.packages.append(pkg)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || studentID == nil || Double(pricePaid) == nil)
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
