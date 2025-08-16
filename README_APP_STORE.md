# App Store Connect Prep (WoWCA)

## Versioning
- Run `./bump_version.sh 1.1.0` (or omit version to just bump build).
- Commit & tag: `git commit -am "Release 1.1.0 (2)" && git tag 1.1.0`.

## Archive & Upload
1. In Xcode choose `Any iOS Device (arm64)`.
2. Product > Archive.
3. Organizer: Validate then Distribute (App Store Connect).

## Store Metadata Suggestions
| Field | Value |
|-------|-------|
| App Name | WoW Classic Armory |
| Subtitle | Classic item & spell reference |
| Category | Reference |
| Keywords | wow, classic, items, armory, raid, prebis, gear |
| Support URL | GitHub issues page |
| Privacy Policy URL | https://gunnarguy.github.io/WoWCA/privacy (update once hosted) |

## Screenshots Needed
- iPhone 6.7" (5–10 shots) search, item detail, spell detail, list.
- iPad 12.9" (min 2).
- Use light (and optionally dark) mode.

## Compliance
- No custom encryption (use YES for Apple APIs, NO for custom).
- Content rights: numerical/game data only, no copyrighted art.
- Age rating via Apple questionnaire (likely 4+ or 9+ depending on answers).

## Privacy
- No tracking, no data collection (see `PrivacyInfo.xcprivacy`).
- Provide simple policy: All data local, no personal info stored or transmitted.

## Pre-Submission Checklist
- [ ] Version & build bumped
- [ ] Archive validates
- [ ] Screenshots uploaded (iPhone & iPad)
- [ ] Privacy policy hosted & About screen link updated
- [ ] Disclaimer present (About + Store notes if needed)
- [ ] Icon renders correctly (all sizes)
- [ ] App runs on physical device (cold launch OK)
- [ ] Release notes written
- [ ] Export compliance answered
- [ ] (Optional) TestFlight internal testing pass

## Future Enhancements
- Favorites / Recently Viewed
- Settings / Data provenance screen
- Localization (en + more)
- Rarity-based icon variants
- Unit tests for DB queries & search filtering

