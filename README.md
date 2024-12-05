# 🎛️ Relay

Relay is a Swift framework that simplifies recording, replaying, intercepting, and modifying network requests to enhance testing and debugging of network interactions in iOS applications.

## Features

Record, Replay, and Intercept HTTP Network Requests for consistent testing, while filtering and intercepting requests based on URL keywords. Dynamically modify JSON responses by overriding specific key-value pairs for enhanced flexibility.


## Usage

First, import Relay at the top of your Swift file:

```swift
import Relay
```

### Recording and Replaying Requests

To start recording and replaying network requests:

```swift
let processor = Relay.recordAndReplay(
    isRecordingEnabled: true,
    urlKeywords: ["api.example.com"],
    jsonValueOverrides: ["token": "REDACTED"]
)
```

- **`isRecordingEnabled`**: Set to `true` to enable recording; `false` to replay without recording.
- **`urlKeywords`**: An array of keywords to filter and intercept URLs.
- **`jsonValueOverrides`**: A dictionary of JSON keys and their replacement values in responses.
- **`recordingRootFolder`** and **`recordingFolder`**: These parameters are optional. By default, Relay automatically uses the current code file path as the root directory and the current function name as the recording folder. All recordings are saved in the `__RelayRecords__` folder within the specified root directory.

> ⚠️ **Warning:** When replaying network requests with Relay in unit tests, **disable test parallelization** to avoid conflicts, as Relay supports only one replay session at a time. Configure your test suite to run serially by setting the test scheme's `Execution Order` to **Sequential** in Xcode.


### Intercepting Requests & Modifying Responses

To intercept network requests and modify responses without recording:

```swift
Relay.interceptAndModify(
    urlKeywords: ["api.example.com"],
    jsonValueOverrides: ["token": "REDACTED"]
)
```

## Installation

### Swift Package Manager

Relay supports installation via **Swift Package Manager**.

1. In Xcode, select **File > Add Packages**.
2. Enter the repository URL:

   ```
   https://github.com/imodeveloperlab/Relay.git
   ```

3. Choose the version you want to install.
4. Add the package to your project.
