# WoWCA AI Coding Instructions

## Project Overview

WoWCA is a SwiftUI iOS app providing offline World of Warcraft Classic item/spell data. The architecture uses Swift actors for thread-safe database access and modern structured concurrency patterns.

## Core Architecture

### Database Layer (`DatabaseService` + `ItemRepository`)

- **`DatabaseService`**: Singleton that copies bundled `items.sqlite` to Application Support on first launch
- **`ItemRepository`**: Swift actor providing thread-safe database queries via GRDB
- **Critical Pattern**: All database access MUST go through the `ItemRepository` actor to prevent "unsafeForcedSync" concurrency warnings

### Data Models

- **`Item`**: Large struct (~100 properties) representing WoW items with comprehensive stats, spells, and metadata
- **`Spell`**: Contains spell data linked from items via `spellid_1` through `spellid_5` fields
- **Database Schema**: `items` table + `items_fts` (FTS5) + `spells` table + `data_version` metadata

### Search Implementation

- **FTS5 Strategy**: Tokenizes queries, appends `*` for prefix matching (`"sulfu"` → `"sulfu*"`)
- **Numeric Detection**: Direct ID lookup if query is pure integer
- **Enrichment**: Items are enriched with spell data after initial search
- **Debouncing**: 150ms debounce in `ItemSearchViewModel.updateQuery()`

## SwiftUI Patterns

### State Management

- **`@Observable` + `@MainActor`**: `ItemSearchViewModel` uses new observation system
- **`@Bindable`**: Views bind to observable view models
- **Actor Isolation**: Repository work stays in actor, UI updates on `@MainActor`

### Navigation Structure

```
TabView (RootView)
├── SearchView (NavigationStack)
│   ├── ItemRowView (in List)
│   └── ItemDetailViewEnhanced (navigationDestination)
└── AboutView
```

### Error Handling

- Database errors handled gracefully with empty results + logging
- Comprehensive DEBUG logging throughout (`os.log` + `print` statements)
- App continues functioning even if some operations fail

## Development Workflows

### Building & Testing

```bash
# Open in Xcode (standard iOS development)
xed .

# Version management
./bump_version.sh [patch|minor|major]  # Updates both version and build number
```

### Key Dependencies

- **GRDB.swift**: SQLite wrapper enabling FTS5 and type-safe queries
- **SwiftUI + Observation**: Modern reactive UI framework
- **No external data**: App is fully offline with bundled database

## Code Conventions

### Logging Pattern

Every significant operation includes both `os.log` and `print` statements:

```swift
logger.info("🔍 Starting search for: '\(query)'")
print("🔍 Executing search for: '\(query)'")
```

### Concurrency Safety

- Database operations: Always use `ItemRepository` actor
- UI updates: Ensure `@MainActor` context
- Long operations: Use structured concurrency with proper cancellation

### File Organization

- **Flat structure**: All Swift files in `WoWCA/` directory (no subfolders)
- **Naming**: Descriptive names like `ItemDetailViewEnhanced.swift`, `ItemSearchViewModel.swift`
- **Resources**: `items.sqlite` bundled directly in app bundle

## Common Gotchas

### Threading Issues

- **Never** call GRDB synchronously from Swift concurrency contexts
- Always `await` calls to `ItemRepository` methods
- UI state changes must happen on `@MainActor`

### Search Performance

- FTS queries are fast but enrichment with spells adds latency
- Current query comparison prevents stale results during rapid typing
- Empty query handling avoids unnecessary database work

### Database Immutability

- App treats database as read-only (bundled fresh each launch)
- No migrations or user data persistence
- Database copying happens synchronously during app initialization

## Integration Points

### App Store Deployment

- Privacy-focused: No analytics, no network calls, no data collection
- Multi-platform: iOS + iPadOS + visionOS support
- Asset pipeline: Screenshots in `promo/` directory

### Data Pipeline (External)

The app includes a pre-built `items.sqlite` but the original data pipeline:

- Processes public WoW Classic database dumps
- Normalizes and deduplicates item data
- Builds FTS indexes for fast text search
- Outputs reproducible SQLite database
