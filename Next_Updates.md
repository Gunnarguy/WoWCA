# WoWCA Development Progress & Roadmap

## Recently Completed ✅

### Phase 1: Foundational Polish & Compliance ✅ COMPLETED

- **Enhanced Search System**: Implemented comprehensive 5-strategy search system that finds items by name, stats, spell effects, quality, and equipment type
- **Classic WoW Content Filtering**: Removed expansion content (Death Knight, Monk, Demon Hunter, Blood Elf, Draenei) to match 1.15.7
- **Fixed Navigation Issues**: Resolved recent items endless loading bug and navigation conflicts
- **Spell Description Improvements**:
  - Added proper variable substitution ($h for proc chances)
  - Fixed formatting issues (escaped apostrophes, line breaks)
  - Enhanced spell effects display with comprehensive numerical data
- **Weapon Type Mapping**: Fixed incorrect weapon subclass mappings (Atiesh now shows as Staff, not Dagger)

### Phase 2: Core User Experience Refinement ✅ COMPLETED

- **Proc Effect Search**: Precise "chance on hit" searches with 36 different proc patterns supported
- **Stat-Based Search**: Find items by stats like "spell crit", "stamina", "+healing"
- **Enhanced Spell Tab**: All numerical and quantifiable spell information now displayed including:
  - Effect-specific stats (amplitude, multiple values, chain targets)
  - Advanced properties (casting mechanics, mana scaling, targeting details)
  - Proper aura type display and targeting information
- **Search Precision**: Refined search patterns for exact phrase matching vs broad term matching

## Objective

To provide a clear, phased roadmap for making the WoWCA app production-ready. The phases will be organized from the most immediate and highest-impact, low-effort tasks (ideal for an AI agent) to more substantial, long-term architectural improvements.

## Current Status: Ready for Production Polish

The core functionality is now robust and feature-complete. Remaining tasks focus on polish and advanced features.

### Phase 3: Production Polish (Medium-Impact, Low-Effort)

| Task                            | File(s) to Modify                               | Status  | Instructions for an AI Agent                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ------------------------------- | ----------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1. Standardize Logging**      | Entire Project (`.swift` files)                 | Pending | "Scan the entire project. Replace every instance of a `print()` statement with an equivalent `logger.info()` statement using `os.log`. Ensure a `logger` instance is available in each file where a replacement is made. Wrap any verbose, debug-only logging blocks in `#if DEBUG` preprocessor macros."                                                                                                                                                                                                                |
| **2. Add the Legal Disclaimer** | `AboutView.swift`                               | Pending | "In `AboutView.swift`, add a new section at the bottom. It should contain a `Text` view with the following disclaimer in a smaller, secondary font style: _'World of Warcraft ©2004 Blizzard Entertainment, Inc. All rights reserved. World of Warcraft, Warcraft and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. in the U.S. and/or other countries. This is an unofficial fan-made application and is not affiliated with or endorsed by Blizzard Entertainment.'_" |
| **3. Clean Up Code Comments**   | `DatabaseService.swift`, `ItemRepository.swift` | Pending | "Review the existing `print` statements that were converted to logs in `DatabaseService.swift` and `ItemRepository.swift`. These were used for debugging and are now redundant. Remove these verbose log entries (e.g., 'Database configuration lock released', 'Starting database read transaction...') to clean up the code, but retain the higher-level logs that describe the start and end of major operations (e.g., 'search() called...', 'FTS search returned X items')."                                        |
| **4. Enhance Onboarding Copy**  | `OnboardingView.swift`                          | Pending | "Update the `OnboardingView.swift` to be more descriptive. Create a simple, multi-page view that explains the three core features: Searching (by name or ID), Favorites (for saving items), and Recents (for your history). Use SwiftUI's built-in SF Symbols to add visual cues for each feature."                                                                                                                                                                                                                      |

---

### Phase 4: Advanced Features (High-Impact, High-Effort)

These are the "monumental" tasks that will significantly expand the app's capabilities and robustness. They should be tackled after the lower-effort phases are complete.

| Task                            | Rationale                                                                                                                                                                                                                                                 |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Implement Search Filters** | The single most impactful new feature you can add. It transforms the app from a simple lookup tool into a powerful discovery engine. Users need to be able to filter by item type, quality, level, etc.                                                   |
| **2. Add Item Set Data**        | When a user views a piece of a set, their immediate next question is, "What are the other pieces and what are the set bonuses?" Answering this question within the app would be a massive value-add. This would require adding set data to your database. |
| **3. Refactor for iPad/macOS**  | Creating a responsive layout with `NavigationSplitView` would make the app a first-class citizen on all Apple platforms, greatly expanding its appeal and demonstrating a high level of polish to App Store reviewers.                                    |
