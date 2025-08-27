# WoWCA: World of Warcraft Classic Assistant

<p align="center">
  <img src="https://raw.githubusercontent.com/Gunnarguy/WoWCA/main/WoWCA/Assets.xcassets/AppIcon.appiconset/icon-mac-256@2x.png" width="128" alt="WoWCA Icon">
</p>

**WoWCA** is a comprehensive, offline-first item and spell database for World of Warcraft Classic, meticulously crafted for iOS, iPadOS, and visionOS. It provides instant access to a vast repository of in-game items and spells without requiring an internet connection, ensuring data is always available, private, and fast.

The project includes a modern SwiftUI client and a fully reproducible data build pipeline that generates the app's core SQLite database.

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
- **Multi-Platform**: Designed for iOS, with full support for iPadOS and visionOS multitasking and layouts.
- **Comprehensive Item Details**: View stats, damage, speed, armor, resistances, durability, level requirements, and class/race restrictions.
- **Detailed Spell Information**: See spell effects, proc chances ("Chance on Hit"), and "Use:" abilities tied to items.
- **Advanced Search**:
  - **Prefix Search**: Instantly find items by typing the first few letters of their name (e.g., `sulfu` for Sulfuras).
  - **Wildcard Search**: Use `*` for broader matching (e.g., `gladiat*`).
  - **Exact ID Lookup**: Search directly for an item's numerical ID (e.g., `19019`).
  - **Spell Text Search**: Find items with specific effects (e.g., `chance on hit` or `restores mana`).
- **Privacy-Focused**: No analytics, no trackers, no ads, and no data ever leaves your device.
- **Reproducible & Transparent Build**: The entire database is built using a deterministic script, ensuring full transparency from public data sources to the final app.
- **Modern Tech Stack**: Built with SwiftUI, the actor model for safe database access, and modern structured concurrency.

---

## Architecture Overview

### Data Pipeline

The data pipeline consists of a series of scripts that transform raw, publicly available Classic WoW data into a clean, normalized, and optimized SQLite database. This database is then bundled directly into the app.

The process is orchestrated by `items_build.sh`:

1.  **Acquire Data**: Starts with a vendored SQL dump from a public Classic WoW database project.
2.  **Parse & Normalize**: A Python script processes the raw data, cleaning up inconsistencies, normalizing field names, and selecting only the columns needed by the app.
3.  **Resolve Conflicts**: Handles duplicate item entries by intelligently selecting the most accurate version, typically based on the latest patch in which the item appeared.
4.  **Build Database**: Creates the final `items.sqlite` file, including:
    - `items` table: Contains all structured item data.
    - `spells` table: Contains spell data linked from items.
    - `items_fts`: An FTS5 virtual table for high-speed text search.
    - `data_version`: A metadata table that records the source data's commit hash and snapshot date for provenance.
5.  **Package**: The final database is copied into the Xcode project's `Resources` directory to be included in the app bundle.

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
├── WoWCAApp.swift           # App entry point
├── Data/
│   ├── Item.swift           # Main data model
│   ├── Spell.swift          # Spell data model
│   ├── DatabaseService.swift # Manages the SQLite DB file
│   └── ItemRepository.swift # Actor for DB queries
├── ViewModels/
│   └── ItemSearchViewModel.swift # State management for search
├── UI/
│   ├── RootView.swift       # Main navigation view
│   ├── SearchView.swift     # Search interface
│   ├── ItemDetailViewEnhanced.swift # Item detail screen
│   └── AboutView.swift      # About & stats screen
├── Resources/
│   └── items.sqlite         # The bundled database
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
# Or open WoWCA.xcodeproj from Finder
```

Once the project is open, select the `WoWCA` scheme and choose a target (any iOS Simulator or a connected physical device). Click the "Run" button. The app will build, and the included `items.sqlite` will be automatically copied on first launch.

---

## Rebuilding the Database

To regenerate the `items.sqlite` database from the source data, run the main build script from the project root.

```bash
./items_build.sh
```

This script will perform all the steps described in the [Data Pipeline](#data-pipeline) section.

**Expected Outputs**:

- `build/items.sqlite`: The newly generated database.
- The script will automatically copy this file to `WoWCA/Resources/items.sqlite`, replacing the old version.

**Verification**:
You can run queries against the new database to ensure it was built correctly.

```bash
# Count total items
sqlite3 build/items.sqlite 'select count(*) from items;'

# Perform a sample FTS search
sqlite3 build/items.sqlite "select entry,name from items_fts where items_fts match 'sulfuras*' limit 5;"
```

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

1.  **Update Version**: Use the helper script to increment the version and build numbers.
    ```bash
    ./bump_version.sh patch   # Or minor / major
    ```
2.  **Prepare Assets**:
    - Update screenshots for all required device sizes.
    - Ensure the app icon is finalized.
3.  **Archive in Xcode**:
    - Select "Any iOS Device (arm64)" as the target.
    - Go to `Product` -> `Archive`.
4.  **Validate and Distribute**:
    - From the Xcode Organizer, select the archive.
    - Click "Validate App" and resolve any issues.
    - Click "Distribute App" to upload to App Store Connect.
5.  **App Store Connect Metadata**:
    - Fill out the release version details, including "What's New".
    - Confirm keywords, categories, and pricing.
    - Provide the Privacy Policy URL.
    - In the "App Privacy" section, confirm that the app collects no data.
6.  **Submission**:
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

This project is an independent, fan-made reference tool and is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment, Inc. "World of Warcraft" and all related names, logos, and trademarks are the property of Blizzard Entertainment, Inc.

This app uses only numerical and textual data derived from publicly accessible community-driven sources. No proprietary artwork, copyrighted assets, or private server data is included or distributed.

---

## Third‑Party & Licensing

| Component       | Purpose                     | License     |
| --------------- | --------------------------- | ----------- |
| GRDB.swift      | SQLite wrapper / FTS access | MIT         |
| Python (stdlib) | Data pipeline scripting     | PSF License |

The WoWCA project source code is licensed under the MIT License. See `LICENSE` for details.

---

## Future Ideas

- **Database Caching**: Retain the database between launches instead of re-copying, and implement a migration strategy for updates.
- **Unit Tests**: Add lightweight tests for search edge cases (e.g., numeric vs. text, empty queries, special characters).
- **User Features**:
  - **Favorites**: Allow users to save items to a "favorites" list.
  - **Recently Viewed**: Keep a list of recently viewed items.
  - (These would require enabling write access and a proper database migration plan).
- **Data Diffing**: Create tools to compare item stats across different data snapshots or patches.

---

## Issue Reporting

Please open an issue on GitHub with the following details:

- **For Bugs**: Steps to reproduce the issue.
- **For Data Discrepancies**: The item name and ID, and the expected vs. observed values.
- **Diagnostics**: Include the diagnostic information from the `About` screen to help speed up triage.

---

MIT © 2025 Gunndamental
