import SwiftUI

@main
struct Nata_NowApp: App {
    @StateObject private var viewModel = CompassViewModel()

    var body: some Scene {
        WindowGroup {
            CompassView(viewModel: viewModel)
        }
    }
}
