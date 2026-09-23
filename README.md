# Classic Era Assistant

<p align="center">
  <img src="https://raw.githubusercontent.com/Gunnarguy/WoWCA/main/WoWCA/Assets.xcassets/AppIcon.appiconset/icon-mac-256@2x.png" width="128" alt="WoWCA Icon">
</p>

**Classic Era Assistant** is a comprehensive, offline-first item and spell database for the Classic Era of a certain popular MMORPG, meticulously crafted for iPhone (iOS 17.0 or later). It provides instant access to a vast repository of in-game items and spells without requiring an internet connection, ensuring data is always available, private, and fast.

The project includes a SwiftUI client and its bundled SQLite database, `WoWCA/items.sqlite`.

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
  - [Data Pipeline](#data-pipeline)
  - [iOS Application](#ios-application)
- [Project Structure](#project-structure)
- [Building & Running](#building--running)
- [Rebuilding the Database](#rebuilding-the-database)
- [Search Functionality](#search-functionality)
- [App Store Deployment Checklist](#app-store-deployment-checklist)
- [Privacy & Disclaimer](#privacy--disclaimer)
  - [Privacy](#privacy)
  - [Disclaimer](#disclaimer)
- [Third‑Party & Licensing](#thirdparty--licensing)
- [Future Ideas](#future-ideas)
- [Issue Reporting](#issue-reporting)

---

## Features

- **100% Offline Access**: All item and spell data is stored locally. No network connection required.
- **Platform**: Crafted for iPhone (iOS 17.0 or later).
- **Comprehensive Item Details**: View stats, damage, speed, armor, resistances, durability, level requirements, and class/race restrictions.
- **Detailed Spell Information**: Complete spell effects with proper variable substitution, proc chances, and comprehensive numerical data in the enhanced spells tab.
- **Classic WoW Accuracy**: Content properly filtered for Classic WoW 1.15.7 - no expansion classes or races shown.
- **Favorites & Recents**: Save favorite items and track recently viewed items for quick access.
- **Enhanced User Experience**: Smooth navigation, fixed recent items functionality, and clean spell description formatting.
- **Advanced Search**:
  - **Smart Search**: Comprehensive multi-strategy search that finds items by name, stats, spell effects, quality, and equipment type
  - **Stat-Based Search**: Find items by stats like "spell crit", "stamina", "strength", or "+healing"
  - **Effect-Based Search**: Search for specific spell effects like "chance on hit", "extra attack", "proc", or "mana restore"
  - **Prefix Search**: Instantly find items by typing the first few letters of their name (e.g., `sulfu` for Sulfuras)
  - **Wildcard Search**: Use `*` for broader matching (e.g., `gladiat*`)
  - **Exact ID Lookup**: Search directly for an item's numerical ID (e.g., `19019`)
  - **Quality Search**: Find items by rarity like "epic", "rare", "uncommon"
  - **Equipment Type Search**: Search by item type like "staff", "dagger", "trinket"
- **Privacy-Focused**: No analytics, no trackers, no ads, and no data ever leaves your device.
- **Data Provenance**: The database records its source, patch and build date in `data_version`.
- **Modern Tech Stack**: Built with SwiftUI, the actor model for safe database access, and modern structured concurrency.

---

## Architecture Overview

### Data Pipeline

The app ships a prebuilt SQLite database, `WoWCA/items.sqlite`. The scripts that built it were removed in 15639f0. It includes:

- `items` table: Contains all structured item data.
- `spell_template_ultimate_nerd`: spell data linked from items.
- `items_fts`: An FTS5 virtual table for high-speed text search.
- `data_version`: patch version, build date, source and item count.

### iOS Application

The app is designed with a clean, modern architecture that leverages the latest Swift and SwiftUI features.

- **`DatabaseService`**: A singleton responsible for managing the database. On first launch, it copies the bundled `items.sqlite` from the app bundle to a writable location in the Application Support directory.
- **`ItemRepository` (actor)**: A Swift actor that provides a safe, serialized interface for all database read operations. This prevents data races and ensures that all database access is thread-safe.
- **`ItemSearchViewModel` (@MainActor)**: Manages the state for the search view, including the user's query, the search results, and loading/empty states. It communicates with the `ItemRepository` to fetch data.
- **Views**:
  - `SearchView`: The main user interface for searching items.
  - `ItemDetailViewEnhanced`: A detailed view showing all stats and information for a selected item.
  - `AboutView`: A comprehensive screen with app details, data provenance, privacy information, and technical stats about the database.

---

## Project Structure

```
WoWCA/
├── ClassicDBApp.swift       # App entry point
├── Item.swift               # Main data model
├── Spell.swift              # Spell data model
├── DatabaseService.swift    # Manages the SQLite DB file
├── ItemRepository.swift     # Actor for DB queries
├── ItemSearchViewModel.swift # State management for search
├── RootView.swift           # Main navigation view
├── SearchView.swift         # Search interface
├── ItemDetailViewEnhanced.swift # Item detail screen
├── AboutView.swift          # About & stats screen
├── items.sqlite             # The bundled database
└── ... (other supporting files)
```

---

## Building & Running

**Prerequisites**:

- macOS with Xcode installed.

**Steps**:

```bash
# 1. Clone the repository
git clone https://github.com/Gunnarguy/WoWCA.git
cd WoWCA

# 2. Open the project in Xcode
xed .
# Or open ClassicDB.xcodeproj from Finder
```

Once the project is open, select the `WoWCA` scheme and choose a target (any iOS Simulator or a connected physical device). Click the "Run" button. The app will build, and the included `items.sqlite` will be automatically copied on first launch.

---

## Rebuilding the Database

The build scripts were removed in 15639f0.

---

## Search Functionality

The app's search is powered by SQLite's FTS5 extension, offering several ways to find items:

- **Prefix Match**: Simply type the beginning of an item's name. The search is case-insensitive.
  - Example: `arcanite` finds "Arcanite Reaper".
- **Wildcard Match**: Use an asterisk (`*`) to match any characters, useful for finding items with a common root name.
  - Example: `gladiat*` finds all items starting with "Gladiator".
- **Exact ID Match**: Enter the numeric ID of an item to jump directly to it.
  - Example: `19019` finds "Thunderfury, Blessed Blade of the Windseeker".
- **Spell Text Match**: Search for phrases in item effects or "Use:" descriptions.
  - Example: `chance on hit` or `restores 20 mana`.

---

## App Store Deployment Checklist

1.  **Prepare Assets**:
    - Update screenshots for all required device sizes.
    - Ensure the app icon is finalized.
2.  **Archive in Xcode**:
    - Select "Any iOS Device (arm64)" as the target.
    - Go to `Product` -> `Archive`.
3.  **Validate and Distribute**:
    - From the Xcode Organizer, select the archive.
    - Click "Validate App" and resolve any issues.
    - Click "Distribute App" to upload to App Store Connect.
4.  **App Store Connect Metadata**:
    - Fill out the release version details, including "What's New".
    - Confirm keywords, categories, and pricing.
    - Provide the Privacy Policy URL.
    - In the "App Privacy" section, confirm that the app collects no data.
5.  **Submission**:
    - Submit for review. Optionally, release to a limited set of users via TestFlight first.

---

## Privacy & Disclaimer

### Privacy

This application is designed with user privacy as a core principle.

- **No Data Collection**: The app does not collect, store, or transmit any user data.
- **No Analytics**: There are no analytics, crash reporters, or tracking identifiers of any kind.
- **No Network Activity**: The app performs no network calls. All functionality is self-contained and works entirely offline.
- **No User Accounts**: The app does not require or support user accounts.

### Disclaimer

This project is an independent, fan-made reference tool and is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment, Inc. "World of Warcraft" and all related names, logos, and trademarks are the property of Blizzard Entertainment, Inc. The use of the trademark is for identification purposes only.

This app uses only numerical and textual data derived from publicly accessible community-driven sources. No proprietary artwork, copyrighted assets, or private server data is included or distributed.

---

## Third‑Party & Licensing

| Component       | Purpose                     | License     |
| --------------- | --------------------------- | ----------- |
| GRDB.swift      | SQLite wrapper / FTS access | MIT         |

The WoWCA project source code is licensed under the MIT License. See `LICENSE` for details.

---

## Future Ideas

- **Unit Tests**: Add lightweight tests for search edge cases (e.g., numeric vs. text, empty queries, special characters).
- **Data Diffing**: Create tools to compare item stats across different data snapshots or patches.

---

## Issue Reporting

Please open an issue on GitHub with the following details:

- **For Bugs**: Steps to reproduce the issue.
- **For Data Discrepancies**: The item name and ID, and the expected vs. observed values.
- **Diagnostics**: Include the diagnostic information from the `About` screen to help speed up triage.

---

## Screenshots

<p align="center">
  <img src="promo/Simulator Screenshot - iPhone 16 Pro Max - 2025-08-26 at 20.56.24.png" width="200" alt="Screenshot 1">
  <img src="promo/Simulator Screenshot - iPhone 16 Pro Max - 2025-08-26 at 20.56.37.png" width="200" alt="Screenshot 2">
  <img src="promo/Simulator Screenshot - iPhone 16 Pro Max - 2025-08-26 at 20.56.43.png" width="200" alt="Screenshot 3">
  <img src="promo/Simulator Screenshot - iPhone 16 Pro Max - 2025-08-26 at 20.56.53.png" width="200" alt="Screenshot 4">
</p>

---

MIT © 2025 Gunndamental
