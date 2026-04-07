import SwiftUI

struct ClassListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false

    private var sortedSessions: [ClassSession] {
        store.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            ForEach(sortedSessions) { session in
                HStack {
                    VStack(alignment: .leading) {
                        Text(store.student(for: session.studentID)?.name ?? "Unknown Student")
                            .font(.headline)
                        Text("with \(store.teacher(for: session.teacherID)?.name ?? "Unknown Teacher")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(session.date, style: .date)
                            .font(.subheadline)
                        HStack(spacing: 8) {
                            if let duration = session.durationMinutes {
                                Text("\(duration)min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let pkg = store.package(for: session.packageID) {
                                Text(pkg.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        if let idx = store.sessions.firstIndex(where: { $0.id == session.id }) {
                            store.sessions.remove(at: idx)
                            store.save()
                        }
                    }
                }
            }
        }
        .navigationTitle("Classes")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add Class", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ClassFormView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
        }
    }
}
