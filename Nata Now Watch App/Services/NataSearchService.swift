import Foundation
import MapKit
import Combine

@MainActor
final class NataSearchService: ObservableObject {
    @Published var locations: [NataLocation] = []
    @Published var isSearching = false

    private let searchRadius: CLLocationDistance = 2000 // 2km

    private let nataTier1Keywords = [
        "pastel de nata",
        "pastéis de nata",
        "custard tart",
        "pastelaria",
        "tarte de nata"
    ]

    // Tier 2: Cafés
    private let cafeKeywords = [
        "cafe"
    ]

    // Tier 3: Bakeries
    private let bakeryKeywords = [
        "bakery"
    ]

    func search(near location: CLLocation) async {
        isSearching = true
        defer { isSearching = false }

        var allResults: [NataLocation] = []

        // Search tier 1 keywords first
        for keyword in nataTier1Keywords {
            let results = await performSearch(keyword: keyword, near: location, tier: .nata)
            allResults.append(contentsOf: results)
        }

        // Search cafe keywords
        for keyword in cafeKeywords {
            let results = await performSearch(keyword: keyword, near: location, tier: .cafe)
            allResults.append(contentsOf: results)
        }

        // Search bakery keywords
        for keyword in bakeryKeywords {
            let results = await performSearch(keyword: keyword, near: location, tier: .bakery)
            allResults.append(contentsOf: results)
        }

        // Deduplicate by proximity (within 50m = same place)
        var deduplicated: [NataLocation] = []
        for result in allResults {
            let isDuplicate = deduplicated.contains { existing in
                let existingLoc = CLLocation(latitude: existing.coordinate.latitude, longitude: existing.coordinate.longitude)
                let resultLoc = CLLocation(latitude: result.coordinate.latitude, longitude: result.coordinate.longitude)
                return existingLoc.distance(from: resultLoc) < 50
            }
            if !isDuplicate {
                deduplicated.append(result)
            }
        }

        // Smart fill-to-5: prioritise nata, then cafes, then bakeries
        let userLocation = location
        let sortByDistance: (NataLocation, NataLocation) -> Bool = { a, b in
            let distA = userLocation.distance(from: CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude))
            let distB = userLocation.distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
            return distA < distB
        }

        let nataResults = deduplicated.filter { $0.tier == .nata }.sorted(by: sortByDistance)
        let remaining = deduplicated.filter { $0.tier != .nata }.sorted(by: sortByDistance)

        let maxResults = 5
        var selected = Array(nataResults.prefix(maxResults))
        if selected.count < maxResults {
            selected.append(contentsOf: remaining.prefix(maxResults - selected.count))
        }

        // Update bearing and distance for each result
        locations = selected.map { loc in
            var updated = loc
            updated.distance = userLocation.distance(from: CLLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude))
            updated.bearing = bearing(from: userLocation.coordinate, to: loc.coordinate)
            return updated
        }
    }

    private func performSearch(keyword: String, near location: CLLocation, tier: SearchTier) async -> [NataLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            return response.mapItems.compactMap { item in
                guard let itemLocation = item.placemark.location else { return nil }
                let distance = location.distance(from: itemLocation)
                guard distance <= searchRadius else { return nil }

                return NataLocation(
                    name: item.name ?? "Unknown",
                    coordinate: item.placemark.coordinate,
                    tier: tier,
                    bearing: bearing(from: location.coordinate, to: item.placemark.coordinate),
                    distance: distance
                )
            }
        } catch {
            print("Search error for '\(keyword)': \(error.localizedDescription)")
            return []
        }
    }

    private func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude.radians
        let lon1 = start.longitude.radians
        let lat2 = end.latitude.radians
        let lon2 = end.longitude.radians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x).degrees

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
