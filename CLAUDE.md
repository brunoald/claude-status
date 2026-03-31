# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build                        # build debug
swift build -c release             # build release
.build/debug/ClaudeStatus &        # run (menu bar app, no dock icon)
pkill -f '.build/debug/ClaudeStatus'  # stop the running instance
```

There are no tests. To iterate: kill the running instance, rebuild, and relaunch.

## Architecture

This is a macOS-only SwiftUI menu bar app (Swift Package, no Xcode project). It requires macOS 13+.

**Data flow:** `StatusManager` fetches `https://status.claude.com/history.rss` on launch and every 3 minutes via a `Timer`. The RSS XML is parsed by `RSSParser` (an `XMLParserDelegate`) into `[StatusItem]`. Each item's `IncidentStatus` is derived by scanning the HTML description for the first `<strong>` keyword (Resolved, Monitoring, Identified, Investigating, Update).

**Menu bar indicator:** `MenuBarIcon` draws a non-template `NSImage` circle in green (all resolved) or orange (any non-resolved item exists). Using `Image(nsImage:)` with `isTemplate = false` is required — SwiftUI `.foregroundColor` on SF Symbols gets overridden to white by macOS in the menu bar.

**Key design decisions:**
- `hasOngoingIncident` scans all items, not just the first, so a resolved top item doesn't mask an active one below it.
- `Sources/Info.plist` sets `LSUIElement = true` to suppress the Dock icon. Swift Package Manager picks it up automatically as a resource warning; it's intentional.
- `RSSParser.extractStatus` checks the *first* matching keyword in order (Resolved → Monitoring → Identified → Investigating → Update), so the most recent update in the description determines the displayed status.
