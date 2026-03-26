import SwiftUI

struct StudentDetailView: View {
    @Environment(DataStore.self) private var store
    let student: Student

    private var studentPackages: [Package] {
        store.packages(for: student.id).sorted { $0.purchaseDate > $1.purchaseDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(student.name)
                    .font(.title.bold())

                if let email = student.email {
                    Label(email, systemImage: "envelope")
                }
                if let phone = student.phone {
                    Label(phone, systemImage: "phone")
                }

                Divider()

                Text("Packages")
                    .font(.title3.bold())

                if studentPackages.isEmpty {
                    Text("No packages yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(studentPackages) { pkg in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(pkg.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(String(format: "%.2f %@", pkg.pricePaid, pkg.currency))
                                        .bold()
                                }
                                let used = store.classesUsed(for: pkg.id)
                                Text("\(used)/\(pkg.totalClasses) classes used")
                                    .foregroundStyle(.secondary)
                                Text(pkg.purchaseDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
