import SwiftUI

struct PackageDetailView: View {
    @Environment(DataStore.self) private var store
    let package: Package

    var body: some View {
        Text(package.name)
    }
}
