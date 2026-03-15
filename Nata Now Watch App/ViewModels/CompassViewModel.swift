import Foundation
import CoreLocation
import Combine

@MainActor
final class CompassViewModel: ObservableObject {
    @Published var heading: Double = 0
    @Published var locations: [NataLocation] = []
    @Published var highlightedLocation: NataLocation?  // Closest to heading (facing)
    @Published var nearestLocation: NataLocation?      // Closest by distance
    @Published var isNearArrival = false
    @Published var hasSearched = false
    @Published var tappedLocation: NataLocation?

    let locationManager = LocationManager()
    let searchService = NataSearchService()

    private var cancellables = Set<AnyCancellable>()
    private var searchTimer: Timer?
    private var tappedTimer: Timer?

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Bind heading
        locationManager.$heading
            .assign(to: &$heading)

        // Bind search results
        searchService.$locations
            .sink { [weak self] locations in
                self?.locations = locations
                self?.updateHighlight()
            }
            .store(in: &cancellables)

        // Trigger search when location updates significantly
        locationManager.$location
            .compactMap { $0 }
            .first() // Search on first location fix
            .sink { [weak self] location in
                Task { [weak self] in
                    await self?.searchService.search(near: location)
                    self?.hasSearched = true
                    self?.startSearchTimer()
                }
            }
            .store(in: &cancellables)

        // Update bearings and highlight when heading changes
        locationManager.$heading
            .sink { [weak self] _ in
                self?.updateHighlight()
            }
            .store(in: &cancellables)

        // Update distances and bearings when location changes
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateLocations(from: location)
            }
            .store(in: &cancellables)
    }

    private func startSearchTimer() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let location = self.locationManager.location else { return }
                await self.searchService.search(near: location)
            }
        }
    }

    private func updateLocations(from userLocation: CLLocation) {
        locations = locations.map { loc in
            var updated = loc
            let locLocation = CLLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            updated.distance = userLocation.distance(from: locLocation)
            updated.bearing = Self.bearing(from: userLocation.coordinate, to: loc.coordinate)
            return updated
        }
        updateHighlight()
    }

    private func updateHighlight() {
        guard !locations.isEmpty else {
            highlightedLocation = nil
            nearestLocation = nil
            isNearArrival = false
            return
        }

        // Nearest by distance
        nearestLocation = locations.min { $0.distance < $1.distance }

        // Closest to current heading (facing)
        let currentHeading = heading
        let facing = locations.min { a, b in
            let diffA = angleDifference(currentHeading, a.bearing)
            let diffB = angleDifference(currentHeading, b.bearing)
            if abs(diffA - diffB) < 1 {
                return a.distance < b.distance
            }
            return diffA < diffB
        }

        highlightedLocation = facing
        isNearArrival = (facing?.distance ?? .infinity) <= 100
    }

    func tapLocation(_ location: NataLocation) {
        tappedLocation = location
        tappedTimer?.invalidate()
        tappedTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tappedLocation = nil
            }
        }
    }

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }

    private static func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}
