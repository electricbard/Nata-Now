# Nata Now — Implementation Plan

## Platform Priority: watchOS first, iPhone second

The Apple Watch is the primary experience — a glanceable compass on your wrist that points you toward the nearest Pastel de Nata. The watch app operates independently (own location + search). iPhone app follows later.

## Architecture Overview

watchOS app using SwiftUI + MVVM. No external dependencies.

```
Nata Now Watch App/
├── NataNowWatchApp.swift         # App entry point
├── Models/
│   └── NataLocation.swift        # Location model (name, coordinate, tier, bearing, distance)
├── Services/
│   ├── LocationManager.swift     # CLLocationManager (location + heading) for watchOS
│   └── NataSearchService.swift   # MKLocalSearch with multilingual nata keywords
├── Views/
│   ├── CompassView.swift         # Full-screen compass dial (Canvas)
│   ├── DistanceReadout.swift     # Centre distance text or sad face
│   └── NearArrivalView.swift     # Throbbing icon at ≤100m
├── ViewModels/
│   └── CompassViewModel.swift    # Orchestrates heading, search, marker state
└── Assets.xcassets/
    └── (nata icon, espresso icon)
```

## Implementation Phases

### Phase 1: Compass Dial (P0)
1. **Create watchOS target** in Xcode project
2. **LocationManager** — CLLocationManager for heading + location on watchOS
3. **CompassView** — Full watch screen, black background, Canvas rendering:
   - 36 tick marks at 10° intervals around circumference
   - North indicator (distinct red marker / "N")
   - Dial counter-rotates with device true heading at ≥10fps
4. Wire up as root view

### Phase 2: Search + Markers (P0)
5. **NataSearchService** — MKLocalSearch with keyword set:
   - Tier 1: "pastel de nata", "pastéis de nata", "pastelaria", "tarte de nata"
   - Tier 2: "custard tart", "egg tart", "patisserie", "bakery"
   - 2km radius, max 6 results, auto-refresh every 2 min
6. **NataLocation model** — coordinate, name, SearchTier (.nata/.cafe), bearing, distance
7. **Markers on dial** — nata/espresso icons at correct bearing, tick occlusion ±5°
8. **Highlight** — orange-red ring on marker closest to current heading direction
9. **Distance readout** — large white text in centre for highlighted location

### Phase 3: Empty State + Near-Arrival (P0)
10. **Empty state** — sad face in centre when zero results
11. **Near-arrival (≤100m)** — replace distance with throbbing nata/espresso icon
    - Pulse: scale 1.0 → 1.15 → 1.0, 1.2s loop

### Phase 4: P1 Polish
12. **Haptics** — WKInterfaceDevice haptic on highlight change + near-arrival
13. **Dynamic radius** — expand to 5km if <2 results
14. **Accessibility** — VoiceOver for highlighted location

## Key Decisions

| Decision | Rationale |
|---|---|
| watchOS independent (no WatchConnectivity) | User wants watch as primary platform; watch has its own CLLocationManager + network for MKLocalSearch |
| MKLocalSearch | Free, no API key, works natively on watchOS |
| CLLocationManager heading on watchOS | Provides true heading on Apple Watch (Series 5+) |
| SwiftUI Canvas for dial | Hardware-accelerated, works on watchOS, 60fps capable |
