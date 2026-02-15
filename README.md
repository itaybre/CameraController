<h1 align="center"> CameraController </h1>
edited by dweebz


<!-- subtext -->
<div align="center">
Control your cameras settings without using the software provided (or not) by the company.
</div>

<br/>

<!-- shields -->
<div align="center">
    <!-- downloads -->
    <a href="https://github.com/itaybre/CameraController/releases">
        <img src="https://img.shields.io/github/downloads/itaybre/CameraController/total" alt="downloads"/>
    </a>
    <!-- version -->
    <a href="https://github.com/itaybre/CameraController/releases/latest">
        <img src="https://img.shields.io/github/release/itaybre/CameraController.svg" alt="latest version"/>
    </a>
    <!-- license -->
    <a href="https://github.com/itaybre/CameraController/blob/master/License.txt">
        <img src="https://img.shields.io/github/license/itaybre/CameraController.svg" alt="license"/>
    </a>
    <!-- platform -->
    <a href="https://github.com/itaybre/CameraController">
        <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="platform"/>
    </a>
</div>

<br/>

<div align="center">
    <img src="./.github/Basic.png" width="299" alt="basic screenshot"/>
    <img src="./.github/Preferences.png" width="299" alt="preferences screenshot"/>
</div>

## Installation

### Manually

Download the latest `.zip` from [Releases](https://github.com/itaybre/CameraController/releases/latest).

### Homebrew

```
brew install --cask cameracontroller
```

## ToDo

- Apply latest settings on startup
- Add more Unit Tests
- Support for some vendor specific capabilities (like Logitech LED control)

## How to help

Open [issues](https://github.com/itaybre/CameraController/issues) if you have a question, an enhancement to suggest or a bug you've found. If you want you can fork the code yourself and submit a pull request to improve the app.

## How to build

### Required

- Xcode
- [Swiftlint](https://github.com/realm/SwiftLint)

Clone the project
```sh
$ git clone https://github.com/itaybre/CameraController.git
```

You're all set ! Now open the `CameraController.xcodeproj` with Xcode

## FAQ

- Does it work with Apple's Facetime Camera?

In old machines it will work, but new machines (wth T1 and T2 chip) require a special entitlement only available to Apple.

## Support
- macOS Catalina (`10.15`) and up.
- Works with cameras controllable via [UVC](https://www.usb.org/document-library/video-class-v15-document-set).

## Contributors
- [@itaybre](https://github.com/itaybre)
- Icons by [@herrerajeff](https://github.com/herrerajeff)
