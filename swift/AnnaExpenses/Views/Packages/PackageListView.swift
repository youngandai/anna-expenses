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
        VStack(spacing: 16) {
            Text("Add Package")
                .font(.title2.bold())

            Form {
                TextField("Package Name", text: $name)
                Picker("Student", selection: $studentID) {
                    Text("Select Student").tag(UUID?.none)
                    ForEach(store.students.sorted { $0.name < $1.name }) { student in
                        Text(student.name).tag(UUID?.some(student.id))
                    }
                }
                Stepper("Total Classes: \(totalClasses)", value: $totalClasses, in: 1...100)
                HStack {
                    TextField("Price Paid", text: $pricePaid)
                    Picker("Currency", selection: $currency) {
                        Text("AED").tag("AED")
                        Text("RUB").tag("RUB")
                        Text("USD").tag("USD")
                    }
                    .frame(width: 100)
                }
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2)
            }
            .formStyle(.grouped)

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
            .padding()
        }
        .frame(width: 450, height: 400)
    }
}
