import SwiftUI

struct TeacherDetailView: View {
    @Environment(DataStore.self) private var store
    let teacher: Teacher

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(teacher.name)
                    .font(.title.bold())
                if let email = teacher.email {
                    Label(email, systemImage: "envelope")
                }
                if let details = teacher.paymentDetails {
                    Label(details, systemImage: "creditcard")
                }
            }
            .padding()
        }
    }
}
