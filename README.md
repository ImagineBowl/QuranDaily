# QuranDaily

QuranDaily is a native iOS app built with SwiftUI for reading and listening to the Quran daily.

## Features

- **Browse** surahs and juz
- **Read** Arabic text with Urdu translation
- **Search** by surah name, ayah reference (e.g. `Yaseen:35`, `36:35`, `262`), or ayah text
- **Read & Listen** — open a surah, scroll to an ayah, and play recitation from that point
- **Sync playback** — highlight the current ayah and auto-scroll as recitation advances
- **Audio** — stream or download Mishari Alafasy recitation
- **Bookmarks** and reading position
- **Offline** Quran text download
- **Settings** — font size and theme

## Architecture

Clean Architecture with clear separation of concerns:

```
Domain/        Models, protocols, use cases
Data/          API client, repositories, services
Presentation/  ViewModels and SwiftUI views
App/           Dependency injection (AppContainer)
```

## Tech Stack

- SwiftUI
- AVPlayer (streaming + ayah-by-ayah playback)
- [alquran.cloud](https://alquran.cloud) API for Quran text and metadata
- [islamic.network](https://islamic.network) CDN for audio recitation

## Requirements

- Xcode 26+
- iOS 26.4+

## Contributing

Even for solo work, use **branches and pull requests** instead of pushing straight to `main`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/ImagineBowl/QuranDaily.git
   cd QuranDaily
   ```
2. Open `QuranDaily.xcodeproj` in Xcode
3. Select an iOS Simulator or device
4. Build and run (`⌘R`)
5. On first launch, download the Quran text for offline reading

## Testing

Run unit tests in Xcode (`⌘U`), or logic tests on macOS:

```bash
./scripts/test-macos.sh
```

## Project Structure

| Folder | Purpose |
|--------|---------|
| `QuranDaily/Domain` | Business logic and models |
| `QuranDaily/Data` | Networking, persistence, audio |
| `QuranDaily/Presentation` | UI and ViewModels |
| `QuranDailyTests` | Unit tests |
| `scripts/` | macOS test runner |

## License

MIT License — see [LICENSE](LICENSE).
