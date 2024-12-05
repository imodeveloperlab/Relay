# Relay

Relay is a Swift framework that simplifies recording, replaying, intercepting, and modifying network requests to enhance testing and debugging of network interactions in iOS applications.

## Features

- **Record and Replay Network Requests**: Capture network traffic and replay recorded sessions for consistent testing.
- **Intercept Requests & Modify Responses**: Filter and intercept network requests based on URL keywords and dynamically alter JSON responses by overriding specific key-value pairs.

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

## Usage

Relay provides both convenience methods for quick setup and detailed configurations for advanced use cases.

### Import Relay

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

**Note**: Recordings are saved in the `__RelayRecords__` folder, which is created automatically if it doesn't exist.

### Intercepting Requests & Modifying Responses

To intercept network requests and modify responses without recording:

```swift
Relay.interceptAndModify(
    urlKeywords: ["api.example.com"],
    jsonValueOverrides: ["token": "REDACTED"]
)
```

## Examples

### Example 1: Basic Recording with Defaults

Record all network requests made to `api.example.com` using default paths:

```swift
Relay.recordAndReplay(
    isRecordingEnabled: true,
    urlKeywords: ["api.example.com"]
)
```

In this example:

- **Recording Root Folder**: Defaults to the current code file path.
- **Recording Folder**: Defaults to the current function name.
- **Recordings are saved in**: `__RelayRecords__` folder within the root directory.

### Example 2: Specifying Recording Paths

If you wish to specify custom paths:

```swift
Relay.recordAndReplay(
    recordingRootFolder: "/path/to/recordings",
    recordingFolder: "testSession",
    isRecordingEnabled: true,
    urlKeywords: ["api.example.com"]
)
```

- **`recordingRootFolder`**: Custom root directory for recordings.
- **`recordingFolder`**: Custom subdirectory for organizing recordings.

### Example 3: Replaying Recorded Requests

Replay previously recorded requests without recording new ones:

```swift
Relay.recordAndReplay(
    isRecordingEnabled: false,
    urlKeywords: ["api.example.com"]
)
```

### Example 4: Modifying JSON Responses

Intercept requests to `api.example.com` and override specific JSON values in the responses:

```swift
Relay.interceptAndModify(
    urlKeywords: ["api.example.com"],
    jsonValueOverrides: [
        "user_id": "12345",
        "session_token": "REDACTED"
    ]
)
```

## Important Notes

### Unit Testing and Parallelization

When using Relay in unit tests to replay network requests without mocking the server results (i.e., using the recorded request responses), it is important to **disable test parallelization**. Relay currently supports only **one replay session at a time**, and running tests in parallel may lead to unexpected behavior or test failures due to shared resources being accessed simultaneously.

To ensure reliable test results, configure your test suite to run these tests serially. You can disable test parallelization in Xcode by setting the `Execution Order` of your test scheme to **Sequential**.

### Supported Protocols

At the moment, Relay supports only **HTTP** requests. Support for other protocols like HTTPS may be added in future releases.

## Configuration

### `RecordingConfig`

A struct that defines recording settings.

- **`rootPath`**: The root directory for storing recordings. Defaults to the current code file path if not provided.
- **`subfolder`**: A subdirectory for organizing session recordings. Defaults to the current function name if not provided.
- **`enableRecording`**: A Boolean flag to enable or disable recording.

#### Initialization

```swift
let recordingConfig = RecordingConfig(
    rootPath: "/path/to/recordings", // Optional
    subfolder: "sessionName",        // Optional
    enableRecording: true
)
```

**Note**: If `rootPath` and `subfolder` are not specified, Relay uses the current file and function names, respectively. Recordings are saved in the `__RelayRecords__` folder within the root directory.

### `InterceptionConfig`

A struct that defines interception and modification settings.

- **`urlKeywords`**: An array of keywords to filter URLs for interception.
- **`jsonValueOverrides`**: A dictionary of JSON keys and their replacement values.

#### Initialization

```swift
let interceptionConfig = InterceptionConfig(
    urlKeywords: ["example.com"],
    jsonValueOverrides: ["api_key": "REDACTED"]
)
```

## Recording Storage

All recordings are saved in the `__RelayRecords__` folder, which is located within the specified `recordingRootFolder`. If `recordingRootFolder` is not specified, it defaults to the path of the current Swift file. The `recordingFolder` parameter (defaulting to the current function name) further organizes recordings into subfolders.

This structure allows Relay to automatically organize recordings based on where in your code the recording is initiated, making it easier to manage and locate specific recordings.
