# 🎛️ Relay

Relay is a Swift framework that simplifies recording, replaying, intercepting, and modifying network requests to enhance testing and debugging of network interactions in iOS applications.

## Purpose

The primary use case for Relay is **unit tests and SwiftUI previews that require server connections**. By recording server responses once and replaying them in subsequent runs, you ensure fast, consistent, and reliable tests without constantly hitting the actual server. Relay also shines in **SwiftUI previews**, allowing you to load previews using previously recorded data. This accelerates the preview process, lets you manipulate a single recorded response for various test states, and avoids repeatedly calling the server.

## Features

- **Record and Replay**: Capture network requests and responses once, and replay them for tests and previews to ensure consistent, reproducible results.
- **Flexible Response Modification**: Dynamically override JSON key-value pairs to simulate different states or conditions using the same recording.
- **Request Interception**: Intercept and optionally modify requests based on URL keywords for enhanced testing and preview scenarios without constant server calls.

## Workflow

1. **Initial Setup and Recording**:  
   - Run your unit test or SwiftUI preview with `isRecordingEnabled = true`.  
   - Relay will record all intercepted network requests and responses during this run.
   
2. **Subsequent Uses with Recorded Data**:  
   - Turn off recording (`isRecordingEnabled = false`) in your tests or previews.  
   - Relay now uses the previously recorded responses, allowing you to quickly test or preview your application’s UI without network latency or server calls.
   
3. **Manipulating Recorded Results**:  
   - Leverage `jsonValueOverrides` to modify parts of the recorded response dynamically, simulating different states or data conditions without needing new recordings.

This approach ensures that:
- Your first run captures real data.
- Subsequent runs are fast and consistent, backed by recorded responses.
- You can easily adjust the data to test a variety of scenarios.

## Usage

First, import Relay at the top of your Swift file:

```swift
import Relay
```

### Recording and Replaying Requests

```swift
let processor = Relay.recordAndReplay(
    isRecordingEnabled: true, // Set to true for your first run to record
    urlKeywords: ["api.example.com"],
    jsonValueOverrides: ["token": "REDACTED"]
)
```

**Parameters:**

- **`isRecordingEnabled`**:  
  - `true`: Capture and store responses for the initial run.  
  - `false`: Subsequent runs use recorded data, ensuring no live server calls.
- **`urlKeywords`**: An array of keywords to filter and intercept URLs.
- **`jsonValueOverrides`**: A dictionary of JSON keys and their replacement values in responses, allowing you to manipulate recorded data.

**Recording Folder Structure:**

- **`recordingRootFolder`**: Automatically detected based on the file in which `recordAndReplay` is invoked, storing all recordings under a `__RelayRecords__` folder.
- **`recordingFolder`**: Defaults to the name of the function from which `recordAndReplay` was called, making it easy to organize and identify which tests produced which recordings.

**Important Note on Test Environments:**

> ⚠️ **Warning:** When replaying network requests with Relay in unit tests, **disable test parallelization**. Relay supports only one replay session at a time. Configure your test suite to run serially by setting the test scheme's `Execution Order` to **Sequential** in Xcode.

### Intercepting Requests & Modifying Responses

To intercept network requests and modify responses without recording:

```swift
Relay.interceptAndModify(
    urlKeywords: ["api.example.com"],
    jsonValueOverrides: ["token": "REDACTED"]
)
```

### Using Custom `URLSession` Configurations

If you're using a custom `URLSession` with a custom `URLSessionConfiguration`, you have two options to ensure that Relay can intercept the requests:

1. **Initialize Relay Before Session Creation**:  
   Call `recordAndReplay` or `interceptAndModify` **before** creating your custom `URLSession`. This ensures the Relay proxy is correctly injected.

2. **Manually Set `protocolClasses`**:  
   If the session is created first, manually set the session’s `protocolClasses` array to include `RelayURLProtocol`:

   ```swift
   static let urlSession: URLSession = {
       let config = URLSessionConfiguration.default
       config.httpAdditionalHeaders = ["x-key": "key", "x-platform": "ios"]
       config.protocolClasses = [RelayURLProtocol.self]
       return URLSession(configuration: config)
   }()
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
