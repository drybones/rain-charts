# RainCharts Widget - Approach Document

## Overview

Add an iOS widget extension to RainCharts with three widget variants showing precipitation charts. The widget's core value is the bubble chart visualization that shows **both** rain probability (Y-axis position) and intensity (bubble size) simultaneously - this richness should be preserved even at widget scale.

## Apple WidgetKit Constraints

### Refresh Budget
- Widgets receive **40-70 refreshes per day** (approximately every 15-60 minutes)
- Budget is dynamically allocated based on user engagement with the widget
- App-triggered updates via `WidgetCenter.shared.reloadAllTimelines()` do **not** consume budget (called when app is running)
- Timeline entries must be at least **5 minutes apart**
- WidgetKit Developer Mode in Settings can bypass budget limits during development

### Runtime Limitations
- Widgets cannot actively request location updates
- No continuous background execution
- Must use pre-computed timeline entries
- Network requests must complete quickly during timeline generation

### Size Families
| Family | Approximate Size | Use Case |
|--------|-----------------|----------|
| `systemSmall` | 169x169 pt | Too small for meaningful chart |
| `systemMedium` | 360x169 pt | Compact chart - primary widget |
| `systemLarge` | 360x376 pt | Full chart with more detail |

**Three widgets, two sizes:**
- **Rain Next Hour** (`systemMedium`) - compact next-hour bubble chart
- **Rain Today & Tomorrow** (`systemMedium`) - compact day-level bubble chart
- **Rain Overview** (`systemLarge`) - both charts stacked

All widgets use `.contentMarginsDisabled()` with manual padding for tighter layout control.

---

## Architecture

### Data Sharing Strategy

The app and widget share data via **App Groups**, but the widget also fetches its own forecast data directly. Widgets can make network requests during timeline generation (they get a ~15-30 second execution window), so the widget calls the same forecast API the app uses. The only thing it needs from the app is a cached location, since widgets cannot reliably use `CLLocationManager`.

```
┌─────────────────┐         ┌─────────────────────────┐
│   Main App      │         │   Widget Extension      │
│                 │         │                         │
│  ContentView    │         │  RainChartWidget        │
│       │         │         │         │               │
│       ▼         │         │         ▼               │
│  ViewModel      │         │  TimelineProvider       │
│       │         │         │    │         │          │
│       ▼         │         │    ▼         ▼          │
│  ForecastService│         │  Reads    ForecastService│
│       │         │         │  location  (live fetch) │
│       ▼         │         │    │         │          │
│  ┌──────────────┴──────────────┘         │          │
│  │     App Group (UserDefaults)  ◄───────┘          │
│  │  - Cached location (JSON)     (writes fallback   │
│  │  - Cached forecast (JSON)      forecast cache)   │
│  └──────────────────────────────────────┘           │
└─────────────────┘         └─────────────────────────┘
```

**App Group data** (`UserDefaults(suiteName: "group.uk.co.drybones.raincharts")`):

| Key | Type | Written by | Read by |
|-----|------|-----------|---------|
| `cachedLocation` | `CachedLocation` (JSON) | Main app on every location update | Widget in `getTimeline` |
| `cachedForecast` | `CachedForecast` (JSON) | Main app after fetch; widget after successful fetch | Widget as fallback when network fails |

**Why the widget fetches its own data:** The forecast changes minute-by-minute (it's minute-level rain prediction), so cached forecast data from the last app session is almost always stale. Location, on the other hand, barely changes for most users -- home and work are fixed. A location cached hours ago is perfectly fine for rain forecasting.

### Code Reuse

**Shared between app and widget** (via target membership, not a framework):
- `RainDataPoint` model (already `Codable`)
- `Forecast` struct (change from `Decodable` to `Codable`)
- `ForecastService` (stateless, uses `URLSession.shared` -- works in widget extension unchanged)
- `RainChart` view (with size adaptations)
- Date rounding extensions

**New shared types:**
```swift
struct CachedLocation: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

struct CachedForecast: Codable {
    let nextHourRainData: [RainDataPoint]
    let nextDayRainData: [RainDataPoint]
    let fetchedAt: Date
    let latitude: Double
    let longitude: Double
}
```

**Widget-specific:**
- `TimelineProvider` implementation (fetches forecast, builds sliding timeline)
- `WidgetEntryView` with per-widget views (`NextHourWidgetView`, `TodayWidgetView`, `CombinedWidgetView`)
- `WidgetChartView` adapted bubble chart with compact/full modes
- `AppGroupStore` helper for reading/writing shared UserDefaults

---

## Implementation Plan

### Phase 1: App Group Setup
1. Create App Group in Apple Developer portal: `group.uk.co.drybones.raincharts`
2. Enable App Groups capability in main app target
3. Create widget extension target with same App Group

### Phase 2: App Group Caching in Main App

Add caching to `ContentViewModel` at two points:

**On location update** (after `self.location = approxLocation`):
```swift
let sharedDefaults = UserDefaults(suiteName: "group.uk.co.drybones.raincharts")
let cachedLocation = CachedLocation(
    latitude: approxLocation.coordinate.latitude,
    longitude: approxLocation.coordinate.longitude,
    timestamp: Date()
)
if let data = try? JSONEncoder().encode(cachedLocation) {
    sharedDefaults?.set(data, forKey: "cachedLocation")
}
```

**On successful forecast fetch** (after `self.forecast = newForecast`):
```swift
let sharedDefaults = UserDefaults(suiteName: "group.uk.co.drybones.raincharts")
let cachedForecast = CachedForecast(
    nextHourRainData: newForecast.nextHourRainData,
    nextDayRainData: newForecast.nextDayRainData,
    fetchedAt: Date(),
    latitude: location.coordinate.latitude,
    longitude: location.coordinate.longitude
)
if let data = try? JSONEncoder().encode(cachedForecast) {
    sharedDefaults?.set(data, forKey: "cachedForecast")
}

// Trigger widget refresh
WidgetCenter.shared.reloadAllTimelines()
```

### Phase 3: Widget Extension

#### File Structure
```
RainChartsWidget/
├── RainChartsWidget.swift          # Three Widget configs + TimelineProvider
├── RainChartsWidgetBundle.swift    # Widget bundle entry point
├── WidgetEntryView.swift           # Per-widget views + shared placeholder components
├── WidgetChartView.swift           # Adapted bubble chart for widget sizes
├── RainChartsWidget.entitlements   # App Groups
├── Info.plist
└── Assets.xcassets
```

#### TimelineProvider Implementation

The widget fetches fresh forecast data in `getTimeline` using the cached location. It falls back to cached forecast data if the network call fails.

**Fallback chain:**
```
1. Read CachedLocation from App Group
   -> If nil: return "Open RainCharts to update" placeholder
   -> Otherwise: use it regardless of age

2. Fetch forecast via ForecastService (live network call)
   -> Success:
      a. Write CachedForecast to App Group (for future fallback)
      b. Build sliding timeline entries (see below)
      c. Return with .atEnd policy
   -> Failure:
      a. Read CachedForecast from App Group
      b. If exists and < 2h old: build timeline from cache
      c. Otherwise: return "Unable to load" entry with .after(15 min) retry
```

**Sliding timeline:** The "next hour" API data often contains more than 60 minutes of data points. The widget generates entries at 5-minute intervals, each showing a rolling 60-minute window for as long as the data allows. Once fewer than 60 minutes of data remain, entries show whatever is left.

```
Example: API returns 90 minutes of data (points 0..89)

Entry 0:  T+0min   -> points [0..59]   (60-min window)
Entry 1:  T+5min   -> points [5..64]   (60-min window)
Entry 2:  T+10min  -> points [10..69]  (60-min window)
...
Entry 6:  T+30min  -> points [30..89]  (60-min window, last full window)
Entry 7:  T+35min  -> points [35..89]  (55 min remaining, shrinking)
...
Entry 11: T+55min  -> points [55..89]  (35 min remaining)
-> .atEnd triggers new getTimeline call
```

This means ~1 refresh per hour, well within the 40-70/day budget.

### Phase 4: Widget Views

Three separate widgets registered in `RainChartsWidgetBundle`, each with its own view:

#### Rain Next Hour (systemMedium)
- `NextHourWidgetView` - "Next hour" headline + compact bubble chart
- 30-minute X-axis tick intervals, hidden Y-axis labels (grid lines only)
- Smaller bubble size multiplier (300 vs 500) for compact fit

#### Rain Today & Tomorrow (systemMedium)
- `TodayWidgetView` - "Today & tomorrow" headline + compact bubble chart
- 8-hour X-axis tick intervals (auto-detected from data range)
- Same compact styling as Next Hour

#### Rain Overview (systemLarge)
- `CombinedWidgetView` - both charts stacked vertically
- 15-minute X-axis ticks for hour data, 8-hour for day data
- Y-axis percentage labels visible
- Fuller padding and headline font

All widgets use `.contentMarginsDisabled()` with manual padding (tighter at bottom than top) for maximum chart area. Shared placeholder views (`PlaceholderViews` enum) handle no-location, no-data, and loading states consistently.

---

## Efficiency Considerations

### Battery & Performance

| Concern | Mitigation |
|---------|------------|
| Network in widget | One lightweight API call per timeline refresh (~1/hour) |
| Refresh frequency | `.atEnd` policy; sliding timeline covers ~1 hour per fetch |
| Location requests | Reuse app's cached location; no CLLocationManager in widget |
| Data size | Fetches both `nextHourRainData` (~60-90 points) and `nextDayRainData` (~24 points) |

### Data Freshness Strategy

The widget is largely self-sufficient for forecast freshness. It fetches its own data using cached location. The only thing that goes stale is location, and only if the user physically moves without opening the app.

1. **App foreground**: App updates cached location and forecast in App Group, triggers `WidgetCenter.shared.reloadAllTimelines()`
2. **Widget timeline**: Fetches fresh forecast using cached location, builds sliding multi-entry timeline
3. **Network failure**: Falls back to cached forecast if < 2 hours old
4. **No cached location**: Shows placeholder prompting user to open app

### Location Staleness UX

Since the forecast is always fetched live, staleness indicators relate to location age only:

| Location age | Behaviour |
|---|---|
| < 1 hour | Normal display, no indicator |
| 1-6 hours | Small "Location from Xh ago" caption |
| > 6 hours | "Location from Xh ago" caption |
| No cached location | Placeholder: "Open RainCharts to update location" |

The widget always uses whatever cached location it has, no matter how old. It never refuses to show data just because the location is stale.

### Memory Efficiency

- Widget views should be lightweight
- Avoid complex computed properties in timeline entries
- Use `ContainerBackground` for proper widget rendering (iOS 17+)

---

## Testing Strategy

1. **WidgetKit Developer Mode**: Enable in Settings > Developer to bypass refresh budgets
2. **Scheme configuration**: Create widget scheme in Xcode for direct widget preview
3. **Preview providers**: Add SwiftUI previews for medium and large sizes
4. **Edge cases**:
   - No cached data
   - Stale cached data (> 2 hours)
   - Empty rain data (no precipitation)
   - App never opened
5. **Chart legibility**: Verify bubble sizes and axis labels are readable at medium size

---

## Files to Create/Modify

### New Shared Files (both targets)
- `Shared/CachedLocation.swift`
- `Shared/CachedForecast.swift`
- `Shared/AppGroupStore.swift` - Read/write helper for App Group UserDefaults

### New Files (Widget Extension)
- `RainChartsWidget/RainChartsWidget.swift` - Three Widget configs (NextHourWidget, TodayWidget, RainChartsWidget) + shared TimelineProvider
- `RainChartsWidget/RainChartsWidgetBundle.swift` - @main entry point registering all three widgets
- `RainChartsWidget/WidgetEntryView.swift` - Per-widget views + shared PlaceholderViews and LocationAgeView
- `RainChartsWidget/WidgetChartView.swift` - Adapted bubble chart with compact/full modes and auto-detected tick intervals
- `RainChartsWidget/RainChartsWidget.entitlements` - App Groups
- `RainChartsWidgetExtension.entitlements` - App Groups (project root)
- `RainChartsWidget/Info.plist`
- `RainChartsWidget/Assets.xcassets`

### Modified Files (Main App)
- `RainCharts.xcodeproj` - Add widget target, App Groups capability, shared file membership
- `ContentViewModel.swift` - Add App Group location/forecast caching + WidgetCenter reload
- `ForecastService.swift` - Change `Forecast` from `Decodable` to `Codable`
- New `RainCharts.entitlements` - Add App Groups entitlement

### Shared via Target Membership (no changes to files themselves)
- `RainDataPoint.swift` - Add to widget target
- `ForecastService.swift` - Add to widget target
- `RainChart.swift` - Add to widget target (size adaptations in the widget view layer)

---

## Decisions Made

1. **Widget names**: "Rain Next Hour", "Rain Today & Tomorrow", "Rain Overview"
2. **Medium widget Y-axis**: Hidden labels, grid lines only (cleaner at compact size)
3. **Content margins**: Disabled via `.contentMarginsDisabled()`, manual padding applied
4. **Background App Refresh**: Skipped for v1 (unreliable scheduling, marginal benefit since location rarely changes while phone is idle). Revisit if user feedback indicates stale location is a problem.

## Open Questions

1. **Accent color**: Match app's rain blue or use system tint?
2. **Tap action**: Deep link to specific view or just open app?

---

## References

- [Apple: Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- [Apple: WidgetFamily documentation](https://developer.apple.com/documentation/widgetkit/widgetfamily)
- [Apple: TimelineProvider documentation](https://developer.apple.com/documentation/widgetkit/timelineprovider)
- [WidgetKit Guide 2025](https://swift-pal.com/ios-widget-guide-everything-beginners-need-to-know-about-widgetkit-in-2025-fb2778025331)
