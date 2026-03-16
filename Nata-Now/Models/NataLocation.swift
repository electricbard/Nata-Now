import Foundation
import CoreLocation

enum SearchTier: Sendable {
    case nata
    case cafe
    case bakery
}

struct NataLocation: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let tier: SearchTier
    var bearing: Double = 0
    var distance: CLLocationDistance = 0
}
