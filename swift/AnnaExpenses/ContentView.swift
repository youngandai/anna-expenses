import SwiftUI

enum SidebarSection: String, CaseIterable {
    case dashboard = "Dashboard"
    case students = "Students"
    case teachers = "Teachers"
    case packages = "Packages"
    case classes = "Classes"
    case transactions = "Transactions"
    case expenses = "Expenses"
    case teacherPayments = "Teacher Payments"
    case importCSV = "Import CSV"

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar"
        case .students: return "person.2"
        case .teachers: return "person.crop.rectangle"
        case .packages: return "shippingbox"
        case .classes: return "calendar"
        case .transactions: return "creditcard"
        case .expenses: return "dollarsign.circle"
        case .teacherPayments: return "banknote"
        case .importCSV: return "square.and.arrow.down"
        }
    }

    var group: String {
        switch self {
        case .dashboard: return "Overview"
        case .students, .teachers, .packages, .classes: return "Manage"
        case .transactions, .expenses, .teacherPayments: return "Finances"
        case .importCSV: return "Data"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Overview") {
                    Label(SidebarSection.dashboard.rawValue, systemImage: SidebarSection.dashboard.icon)
                        .tag(SidebarSection.dashboard)
                }
                Section("Manage") {
                    ForEach([SidebarSection.students, .teachers, .packages, .classes], id: \.self) { item in
                        Label(item.rawValue, systemImage: item.icon)
                            .tag(item)
                    }
                }
                Section("Finances") {
                    ForEach([SidebarSection.transactions, .expenses, .teacherPayments], id: \.self) { item in
                        Label(item.rawValue, systemImage: item.icon)
                            .tag(item)
                    }
                }
                Section("Data") {
                    Label(SidebarSection.importCSV.rawValue, systemImage: SidebarSection.importCSV.icon)
                        .tag(SidebarSection.importCSV)
                }
            }
            .navigationTitle("Anna Expenses")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection {
                case .dashboard:
                    DashboardView()
                case .students:
                    StudentListView()
                case .teachers:
                    TeacherListView()
                case .packages:
                    PackageListView()
                case .classes:
                    ClassListView()
                case .transactions:
                    TransactionListView()
                case .expenses:
                    ExpenseListView()
                case .teacherPayments:
                    TeacherPaymentsView()
                case .importCSV:
                    CSVImportView()
                case nil:
                    Text("Select a section from the sidebar")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 600)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
