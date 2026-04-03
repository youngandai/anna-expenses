# Anna Expenses

Expense management app for Anna's online education business.

## Architecture

- **`swift/`** — Native macOS app (SwiftUI)
- **`web/`** — Web app + API (Next.js, Bun, Supabase)

## Prerequisites

- macOS 14.0+
- Xcode 16.4+ (includes `xcodebuild` CLI)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for regenerating the project file)

```bash
brew install xcodegen
```

## Building the macOS App

### Command line

```bash
cd swift
xcodebuild -project AnnaExpenses.xcodeproj -scheme AnnaExpenses -configuration Debug build
```

The built app will be at `~/Library/Developer/Xcode/DerivedData/AnnaExpenses-*/Build/Products/Debug/AnnaExpenses.app`.

To build and run in one step:

```bash
cd swift
xcodebuild -project AnnaExpenses.xcodeproj -scheme AnnaExpenses -configuration Debug build && \
  open ~/Library/Developer/Xcode/DerivedData/AnnaExpenses-*/Build/Products/Debug/AnnaExpenses.app
```

### Xcode IDE

```bash
open swift/AnnaExpenses.xcodeproj
```

Then **Cmd+R** to build and run.

### Regenerating the Xcode project

If you modify `swift/project.yml` (targets, settings, dependencies), regenerate the `.xcodeproj`:

```bash
cd swift
xcodegen generate
```

> **Note:** `swift build` (Swift Package Manager) is not supported for this project. SPM cannot build macOS apps that use asset catalogs, Info.plist generation, and other Xcode-specific features. The `xcodebuild` CLI — which ships with Xcode — is required.
