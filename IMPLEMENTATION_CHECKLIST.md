# Expert Role
As an expert Senior iOS Engineer and Project Manager, I will break down the previous comprehensive analysis into a phased, actionable plan. This approach prioritizes tasks based on their impact-to-effort ratio, allowing for iterative improvements and identifying which tasks are best suited for an AI assistant to accelerate development.

## Objective
To provide a clear, phased roadmap for making the WoWCA app production-ready. The phases will be organized from the most immediate and highest-impact, low-effort tasks (ideal for an AI agent) to more substantial, long-term architectural improvements.

## Reasoning
Not all development tasks are created equal. By categorizing the necessary work, we can achieve significant progress quickly and build momentum.

* **Phase 1: Foundational Polish & Compliance.** These tasks are non-monumental, have a high return on investment for user perception and App Store compliance, and are often repetitive, making them perfect candidates for an AI development assistant. They address the "low-hanging fruit" of app development.
* **Phase 2: Core User Experience Refinement.** This phase focuses on the heart of the app: the data. The tasks involve curating the vast amount of data to be more user-friendly and relevant to the specific context of WoW Classic Era. This requires more nuanced changes but is still highly impactful and largely contained within specific files.
* **Phase 3: Major Feature & Architectural Evolution.** These are the monumental tasks. They involve significant new features or architectural refactoring that will require more planning and development time. While crucial for a best-in-class app, they are not immediate blockers for a solid version 1.0 release.

This phased approach provides a logical progression, ensuring the most critical and simplest tasks are handled first, paving the way for a successful App Store launch.

## Answer
Of course. Let's break down the path to a production-ready app into manageable phases, starting with the highest-impact, lowest-effort tasks that are perfect for assigning to an AI agent.

### Phase 1: Foundational Polish & Compliance (High-Impact, Low-Effort)

These tasks are not monumental and will immediately elevate the quality and professionalism of the app. **These are the ideal tasks to delegate to an AI agent.**

| Task                            | File(s) to Modify                                                                                                  | Instructions for an AI Agent                                                                                                                                                                                                                                                                                     |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Standardize Logging** | Entire Project (`.swift` files)                                                                                      | "Scan the entire project. Replace every instance of a `print()` statement with an equivalent `logger.info()` statement using `os.log`. Ensure a `logger` instance is available in each file where a replacement is made. Wrap any verbose, debug-only logging blocks in `#if DEBUG` preprocessor macros." |
| **2. Add the Legal Disclaimer** | `AboutView.swift`                                                                                                  | "In `AboutView.swift`, add a new section at the bottom. It should contain a `Text` view with the following disclaimer in a smaller, secondary font style: *'World of Warcraft ©2004 Blizzard Entertainment, Inc. All rights reserved. World of Warcraft, Warcraft and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. in the U.S. and/or other countries. This is an unofficial fan-made application and is not affiliated with or endorsed by Blizzard Entertainment.'*" |
| **3. Clean Up Code Comments** | `DatabaseService.swift`, `ItemRepository.swift`                                                                    | "Review the existing `print` statements that were converted to logs in `DatabaseService.swift` and `ItemRepository.swift`. These were used for debugging and are now redundant. Remove these verbose log entries (e.g., 'Database configuration lock released', 'Starting database read transaction...') to clean up the code, but retain the higher-level logs that describe the start and end of major operations (e.g., 'search() called...', 'FTS search returned X items')." |
| **4. Enhance Onboarding Copy** | `OnboardingView.swift`                                                                                             | "Update the `OnboardingView.swift` to be more descriptive. Create a simple, multi-page view that explains the three core features: Searching (by name or ID), Favorites (for saving items), and Recents (for your history). Use SwiftUI's built-in SF Symbols to add visual cues for each feature." |

---

### Phase 2: Core User Experience Refinement (Medium-Impact, Medium-Effort)

These tasks focus on making the app's primary function—displaying item data—as clear and useful as possible for a WoW Classic Era player.

| Task                                          | File(s) to Modify                                                                                        | Rationale & Instructions                                                                                                                                                                                                                                                                                                       |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1. Curate the Item Detail View** | `ItemDetailViewEnhanced.swift`                                                                                   | The current view shows many data fields that are not relevant to WoW Classic Era. You should hide these to avoid confusing the user. **Action:** In the `overviewTab` and `detailsTab`, comment out the UI sections that display the following properties: `stat_type[8-10]`, `dmg_type[2-5]`, `required_honor_rank`, `area_bound`, `map_bound`, `other_team_entry`, and all fields from the `lootPropertiesSection` except `random_property`. |
| **2. Improve Stat Grouping** | `Item.swift` and `ItemDetailViewEnhanced.swift`                                                                    | A long list of stats is hard to parse. Grouping them makes the information scannable. **Action:** In `Item.swift`, create new computed properties like `primaryStats`, `offensiveStats`, and `defensiveStats`. Then, in `ItemDetailViewEnhanced.swift`, use these new properties to display the stats under categorized subheadings (e.g., "Primary Attributes", "Combat Ratings"). |
| **3. Add "Clear Recents" Button** | `RecentsView.swift`, `RecentsManager.swift`, `ItemRepository.swift`                                              | This is a standard quality-of-life feature that gives users control. **Action:** Add a "Clear All" button to the toolbar in `RecentsView.swift`. This button's action should call a new `clearRecents()` function in `RecentsManager`, which in turn calls a `clearRecentItems()` function in the `ItemRepository` to execute the `DELETE FROM recent_items` SQL command. |

---

### Phase 3: Major Feature & Architectural Evolution (High-Impact, High-Effort)

These are the "monumental" tasks that will significantly expand the app's capabilities and robustness. They should be tackled after the lower-effort phases are complete.

| Task                       | Rationale                                                                                                                                                                                                                |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1. Implement Search Filters** | The single most impactful new feature you can add. It transforms the app from a simple lookup tool into a powerful discovery engine. Users need to be able to filter by item type, quality, level, etc.               |
| **2. Add Item Set Data** | When a user views a piece of a set, their immediate next question is, "What are the other pieces and what are the set bonuses?" Answering this question within the app would be a massive value-add. This would require adding set data to your database. |
| **3. Refactor for iPad/macOS** | Creating a responsive layout with `NavigationSplitView` would make the app a first-class citizen on all Apple platforms, greatly expanding its appeal and demonstrating a high level of polish to App Store reviewers. |