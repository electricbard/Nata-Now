# PRD: Pastel de Nata Finder
**App Codename:** Nata Now
**Platforms:** iPhone (iOS), Apple Watch (watchOS)
**Version:** 1.0
**Status:** Draft
**Author:** Shahin Etemadzadeh
**Date:** March 15, 2026

---

## Problem Statement

Pastéis de Nata have spread far beyond Portugal — they're now served in bakeries, cafés, and patisseries across Europe, Asia, the Americas, and beyond. But whether you're in Lisbon, London, Macau, or Melbourne, finding the nearest one still requires opening a generic maps app, typing a search query, interpreting a map, and navigating an interface never designed for the singular joy of finding a custard tart. There is no dedicated, ambient, glanceable tool that simply points you toward the nearest Pastel de Nata, wherever in the world you happen to be.

---

## Goals

1. Surface the nearest Pastel de Nata–serving establishments within 2km in under 3 seconds of app launch.
2. Allow a user to orientate themselves toward a target location with zero interaction — simply by looking at their device.
3. Deliver a near-arrival experience (≤100m) that is unmissable and delightful.
4. Function seamlessly on both iPhone and Apple Watch so users can check their wrist without reaching for their phone.
5. Require no sign-in, no configuration, and no onboarding — the app should be immediately useful.

---

## Non-Goals

1. **Turn-by-turn navigation.** The app is a directional pointer, not a navigation system. Users are expected to walk toward the indicated direction and use their own judgement.
2. **User reviews or ratings.** Quality assessment of specific establishments is out of scope; the app is purely for discovery and wayfinding.
3. **Offline mode.** Location search requires network access. Graceful degradation is expected, but a full offline experience is not a v1 requirement.
4. **Pastry variety filtering.** The app searches specifically for Pastéis de Nata. Filtering by other menu items or pastry types is out of scope.
5. **Android / Wear OS support.** This version targets Apple platforms only.

---

## User Stories

### Traveller (Primary Persona)

> *Sofia is travelling abroad and wants a Pastel de Nata but doesn't know the neighbourhood and doesn't want to wrestle with a maps app.*

- As a traveller, I want to open the app and immediately see which direction to walk, so that I don't waste time staring at a map.
- As a traveller, I want to see how far away the nearest location is, so that I can decide whether it's worth the walk.
- As a traveller on foot, I want my phone or watch to alert me when I'm almost there, so that I don't overshoot the bakery.
- As a traveller with several options nearby, I want to see all locations on the compass, so that I can choose the one most convenient to my direction of travel.

### Returning Visitor (Secondary Persona)

> *Marco travels frequently for work and uses the app habitually in every new city to check for spots he hasn't tried.*

- As a returning visitor, I want the app to search automatically so that I always have fresh results without manually refreshing.
- As a returning visitor wearing my Apple Watch, I want a glanceable compass on my wrist, so that I don't need to take out my phone while walking.

---

## Requirements

### P0 — Must Have

#### Launch Screen

- On app launch, a **🔮 crystal ball emoji** is displayed centred on a black background.
- The emoji **pulses** (scale 1.0 → 1.15, 0.6s cycle) to convey that the app is "sensing" nearby locations.
- The launch screen **persists for 3 seconds** before transitioning to the compass dial.
- **Acceptance criteria:** Launch screen appears immediately on app open and transitions to the compass after exactly 3 seconds.

#### Compass Dial

- **The dial fills the available screen space** (edge-to-edge on iPhone; full display on Apple Watch).
- **Background is black.**
- **36 tick marks** are rendered around the circumference of the dial, evenly spaced (every 10°).
- **North (N)** is clearly indicated with a distinct visual marker (e.g. a labelled tick or arrow head) that differentiates it from standard ticks.
- **The dial responds in real time** to device orientation using Core Motion / CMMotionManager (iPhone) and the watch's own motion sensors (Apple Watch). As the device rotates, the dial counter-rotates so that the correct cardinal direction always faces the top of the screen.
- **Acceptance criteria:** Compass heading matches the device's true heading within ±5°, updating at ≥10fps.

#### Location Search

- **On app launch**, a search is performed for establishments serving Pastéis de Nata within a **2km radius** of the user's current location.
- **Searches repeat automatically every 2 minutes** while the app is in the foreground.
- The search uses the device's location (Core Location, "When In Use" permission) and a Points of Interest / Places API query (e.g. Google Places, Apple MapKit, or Foursquare) using a **multilingual keyword set** to maximise global coverage: "pastel de nata", "pastéis de nata", "pastelaria", "custard tart", "egg tart", "tarte de nata".
- Results are returned in **three tiers**: (1) places explicitly associated with Pastéis de Nata (🥧 nata icon), (2) cafés or patisseries that might serve nata (☕ espresso cup icon), and (3) general bakeries (🥐 croissant icon). This allows the app to show something useful even in cities with sparse data, while being honest about confidence.
- **A maximum of 5 locations are displayed** on the dial at any one time, selected using a **smart fill-to-5** strategy: all nata results (up to 5) are included first, then remaining slots are filled with the closest non-nata locations by distance (cafés and bakeries interleaved by proximity). This prioritises confirmed nata locations while ensuring the closest alternatives always appear.
- **Acceptance criteria:** Results are displayed within 3 seconds of a search completing on a standard LTE connection. Tier classification is determined before rendering.

#### Location Markers on the Dial

- Up to **5 locations** are shown on the dial simultaneously, selected by the smart fill-to-5 strategy. Each is represented by an icon placed at the bearing corresponding to that location from the user's current position: a **🥧 nata icon** for confirmed nata-serving locations, a **☕ café icon** for patisseries/cafés, or a **🥐 bakery icon** for general bakeries.
- **Icons occlude ticks** — any tick mark that would visually overlap with or sit within 5° of an icon is hidden, preventing clutter.
- **Icon scaling** distinguishes the highlighted location: all icons render at **75% size** by default. The **highlighted location** (the one closest to the direction the device is facing, or the most recently tapped location) renders at **100% size**. This creates a clear visual focus without rings or borders.
- **Nearest indicator:** The **closest location by distance** is marked with a small **orange-red dot** at a **fixed radial distance from the centre** of the dial, along the same bearing as the location's icon. The dot sits on a concentric circle inside the icon track, so it remains positionally stable as the compass rotates. This dot is always visible regardless of device orientation or which location is highlighted.
- **The name and distance of the highlighted location** are displayed in the **centre of the screen**. The location name appears above the distance readout. Distance is shown in kilometres to one decimal place (e.g. "1.4 km") or in metres when under 1km. Font should be large, legible, and white.
- **Acceptance criteria:** Bearings are accurate to within ±3° of the actual geographic bearing. Highlight updates smoothly with device rotation.

#### Empty State

- If **no locations are found** within 2km (no nata, café, or bakery results), a **sad face** (emoji or illustrated icon) is displayed in the centre of the dial in place of the distance readout. The app does not attempt to expand the search radius automatically — the empty state is presented honestly.
- **Acceptance criteria:** Sad face appears within 1 second of a search returning zero results.

#### Near-Arrival Experience

- When the user is **within 100m** of the highlighted location:
  - The distance readout is **replaced by a large icon** in the centre of the screen — a **🥧 nata icon** if the highlighted location is a confirmed nata match, a **☕ café icon** if it is a café/patisserie, or a **🥐 bakery icon** if it is a general bakery.
  - The image **throbs** (a looping pulse animation — scale up ~115% and back, ~1.2s cycle) to draw the user's attention.
  - The throbbing continues until the user moves beyond 100m or the app is closed.
- **Acceptance criteria:** Transition from distance readout to throbbing icon occurs within 1 GPS update cycle of crossing the 100m threshold. Animation runs at ≥30fps.

---

### P1 — Nice to Have

- **Haptic feedback** on iPhone when the highlighted location changes (a short tap) and when the user enters the 100m near-arrival zone (a distinct double-tap).
- **Apple Watch complication** showing the bearing arrow and distance to the nearest location, glanceable from the watch face.
- **Dynamic search radius** — if fewer than 2 results are found at 2km (across all three tiers), automatically retry at 5km and indicate the expanded radius with a subtle UI label (e.g. "Searching 5km").
- **Location name tooltip** — tapping a nata image on the dial (iPhone only) reveals the establishment name in a small floating label.
- **Accessibility:** VoiceOver support announcing the name and distance of the highlighted location when it changes.

---

### P2 — Future Considerations

- **Saved favourites** — allow users to bookmark a location to pin it to the dial even if it falls outside the search results.
- **Widget support** (iOS Lock Screen / Home Screen widget) showing bearing and distance at a glance.
- **watchOS independent operation** — allow the Apple Watch app to fetch its own search results independently when the iPhone is out of range. (v1 requires iPhone to be nearby.)
- **Related pastry modes** — a toggle to also surface similar custard tarts by local names (e.g. *dàn tǎ* in Hong Kong, *pastel de Belém* variants, *bolo de nata*) for users who are happy with near-equivalents when the real thing isn't available.
- **Share to Maps** — one tap to hand off the highlighted location to Apple Maps for full turn-by-turn navigation.

---

## Technical Architecture Notes

*(For engineering reference — not prescriptive)*

| Concern | Recommended Approach |
|---|---|
| Heading data | `CMMotionManager` (iPhone), `WKInterfaceDevice` heading (Watch) |
| Location | `CoreLocation` — "When In Use" authorisation |
| POI Search | Google Places API (Text Search) recommended for global coverage with multilingual keyword set; MapKit `MKLocalSearch` as fallback |
| Dial rendering | `SwiftUI Canvas` or `SpriteKit` for real-time rotation at 60fps |
| Watch connectivity | `WatchConnectivity` framework to pass search results from iPhone to Watch |
| Background refresh | `BGAppRefreshTask` (iOS) — note: 2-min foreground timer only; background refresh subject to OS throttling |

---

## Success Metrics

### Leading Indicators *(visible within days/weeks)*

| Metric | Target |
|---|---|
| App launch → first result displayed | < 3 seconds (p95) |
| Compass heading accuracy | Within ±5° of true heading |
| Crash-free sessions | ≥ 99.5% |
| Near-arrival trigger accuracy | Fires within 1 GPS cycle of crossing 100m |

### Lagging Indicators *(visible over weeks/months)*

| Metric | Target |
|---|---|
| D1 retention (users returning the next day) | ≥ 40% |
| Session length while travelling | ≥ 3 minutes average |
| App Store rating | ≥ 4.5 stars |
| Near-arrival events per session (proxy for successful finds) | ≥ 0.5 per active session globally |

---

## Decisions Made

| # | Decision |
|---|---|
| 1 | **Three-tier fuzzy matching.** Nata locations shown with 🥧, cafés/patisseries with ☕, and bakeries with 🥐 — rather than excluded. |
| 2 | **Max 5 locations** displayed on the dial at any time, using smart fill-to-5 (nata first, then closest cafés/bakeries by distance). |
| 3 | **No automatic radius expansion** on empty results. Pure sad face. |
| 4 | **Free app, no monetisation** in v1. API cost is an accepted running expense. |
| 5 | **Apple Watch shows a full compass dial** and operates in companion mode (iPhone required nearby) in v1. |

---

## Open Questions

| # | Question | Owner |
|---|---|---|
| 1 | Which POI / Places API is preferred? The app is free so per-query billing is a real concern — MapKit MKLocalSearch has no cost but may return sparse results in some cities; Google Places API has better global coverage but charges per query. | **Engineering** |
| 2 | What is the visual style for the nata and espresso cup icons — illustrated/flat, photorealistic, or emoji-adjacent? Does this need a design pass or can it ship with stock assets? | **Design** |
| 3 | Is a "When In Use" location permission sufficient for the near-arrival trigger, or does it require "Always On" to fire reliably when the app is backgrounded? | **Engineering** |
| 4 | Should the 2-minute search interval pause when the user is stationary (e.g. no movement for > 5 minutes) to conserve battery? | **Engineering** |
| 5 | Are there App Store guideline concerns around apps focused on a single food type? Apple has historically been cautious about "too narrow" utility apps — framing as a global travel tool may help. | **Product / Legal** |

---

## Timeline Considerations

| Milestone | Notes |
|---|---|
| **Prototype (compass + heading)** | Core Motion integration and dial rendering — no network dependency. Validates the core UX feel. |
| **Alpha (search + markers)** | POI API integrated, nata icons on dial, distance readout functional. |
| **Beta (Watch + near-arrival)** | WatchConnectivity integration, throbbing near-arrival animation, P1 haptics. |
| **App Store submission** | TestFlight with real-world testing in at least two cities with known nata presence (e.g. Lisbon and London) strongly recommended before submission. |

No hard deadline has been specified. Real-world validation across more than one city is recommended before submission — search result quality will vary significantly by location and POI API choice, and this needs to be validated on the ground.

---

## Appendix: Key UX Principles

- **Zero friction.** No login, no settings, no onboarding screens. Open → works.
- **Ambient over interactive.** The app is read, not operated. Interactions (taps, gestures) are enhancements, not requirements.
- **Delight at every step.** The compass, the icons, and especially the throbbing nata should feel joyful and slightly playful — this is an app about a pastry.
