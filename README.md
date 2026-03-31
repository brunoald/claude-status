# ClaudeStatus

A macOS menu bar app that shows the current [Claude](https://claude.ai) service status at a glance.

![Green dot when all systems operational, orange dot when there's an active incident](https://status.claude.com)

## Features

- **Green dot** — all systems operational
- **Orange dot** — active incident in progress
- Click the icon to see the last 10 incidents with status badges and timestamps
- Click any incident to open it on the status page
- Auto-refreshes every 3 minutes
- No Dock icon — lives entirely in the menu bar

## Requirements

- macOS 13 or later
- Swift 5.9+

## Build & Run

```bash
git clone https://github.com/brunodias/ClaudeStatus
cd ClaudeStatus
swift build
.build/debug/ClaudeStatus &
```

For a release build:

```bash
swift build -c release
.build/release/ClaudeStatus &
```

## How It Works

Fetches the RSS feed at `https://status.claude.com/history.rss` and parses the most recent incidents. An incident is considered "ongoing" if its latest status update is anything other than **Resolved**.

## License

MIT
