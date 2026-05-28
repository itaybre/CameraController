# Copilot Instructions for CameraController

## Build & Test

This is an Xcode project (no SPM Package.swift). Build and test via `xcodebuild`:

```sh
# Build
xcodebuild -project CameraController.xcodeproj -scheme CameraController -sdk macosx build

# Run all tests
xcodebuild -project CameraController.xcodeproj -scheme CameraController -sdk macosx test

# Run a single test
xcodebuild -project CameraController.xcodeproj -scheme CameraController -sdk macosx \
  -only-testing:CameraControllerTests/StringTests/testExtractProductAndVendor test
```

**Linting:** SwiftLint is required. Run `swiftlint` from the repo root.

## Architecture

CameraController is a macOS menu-bar app that controls USB camera settings via the UVC (USB Video Class) protocol. It has three targets:

- **CameraController** – Main app. SwiftUI views rendered in an `NSPopover` from the status bar. Uses `Combine` for reactive state.
- **UVC** – Local framework (imported as `import UVC`). Handles all low-level USB/IOKit communication with cameras. Sends UVC control requests over `IOUSBInterfaceInterface190`.
- **Helper** – Login item helper app (`com.itaysoft.CameraController.Helper`) for launch-at-login via `SMLoginItemSetEnabled`.

### Key data flow

1. `DevicesManager` (singleton) discovers cameras via `AVCaptureDevice.DiscoverySession` and monitors connect/disconnect.
2. `CaptureDevice` wraps an `AVCaptureDevice` and creates a `UVCDevice` (from the UVC framework) to get USB-level access.
3. `DeviceController` exposes camera properties (brightness, contrast, exposure, etc.) as observable `CaptureDeviceProperty` objects that the SwiftUI views bind to.
4. `CaptureDeviceProperty` types (`NumberCaptureDeviceProperty`, `BoolCaptureDeviceProperty`, `BitmapCaptureDeviceProperty`, `MultipleCaptureDeviceProperty`) wrap `UVCControl` subclasses and handle min/max/default/current values.
5. `UVCControl` (and subclasses `UVCIntControl`, `UVCBoolControl`, `UVCBitmapControl`) perform the actual USB control requests to read/write camera settings.

### Profiles

`ProfileManager` persists per-device settings as JSON via `UserDefaults`, allowing users to save and restore camera configurations.

## Conventions

- **Singletons** use `static let shared` pattern (e.g., `DevicesManager.shared`, `UserSettings.shared`).
- **Classes are `final`** unless inheritance is needed.
- **User preferences** are stored in `UserDefaults` with manual key strings, wrapped in `@Published` properties in `UserSettings`.
- **Vendored code** lives in `CameraController/Vendored/` (e.g., LetsMove for app relocation prompts).
- **Auto-updates** use the Sparkle framework (`SPUStandardUpdaterController`).
- **macOS minimum:** 10.15 (Catalina).
- **File headers** follow the Xcode template format with file name, project, author, and copyright.
