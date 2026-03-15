import SwiftUI

@main
struct NataNowWatchApp: App {
    @StateObject private var viewModel = CompassViewModel()

    var body: some Scene {
        WindowGroup {
            CompassView(viewModel: viewModel)
        }
    }
}
