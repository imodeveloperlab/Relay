# 🎛️ Relay

Relay is a Swift framework that simplifies recording, replaying, intercepting, and modifying network requests to enhance testing and debugging of network interactions in iOS applications.

## Purpose

The primary use case for Relay is **unit tests and SwiftUI previews that require server connections**. By recording server responses once and replaying them in subsequent runs, you ensure fast, consistent, and reliable tests without constantly hitting the actual server. Relay also shines in **SwiftUI previews**, allowing you to load previews using previously recorded data. This accelerates the preview process, lets you manipulate a single recorded response for various states, and avoids repeatedly calling the server.

## How It Works

When you run your test or preview with `isRecordingEnabled = true`, Relay intercepts HTTP requests and captures both the request and the corresponding response. These are stored as separate files in a structured directory (e.g., `__RelayRecords__`) relative to the test or preview code file. On subsequent runs, when `isRecordingEnabled = false`, Relay looks up these stored files and returns their recorded responses without making actual network calls. This means you can rely on consistent and stable test inputs and fast-loading previews.

Below is an example of how recorded files might be organized:

```
Tests
 └─ __RelayRecords__
     ├─ customSession
     │   └─ GET-typicode.com-posts_a25b94c312bb64a5
     ├─ defaultSession
     │   └─ GET-typicode.com-posts_e3fdab5b4d16442f
     ├─ handleMultipleRequests
     │   ├─ GET-typicode.com-posts_9986e99294a801c6
     │   ├─ GET-typicode.com-users_1a8fe3094918fe243
     │   └─ POST-typicode.com-posts_ea6ce919bf1be8a6
     ... and so on
```

Each directory represents a specific test scenario or function call, and each file inside corresponds to a particular network request/response pair that Relay recorded.

## Features

- **Record and Replay**: Capture network requests and responses once, and replay them for tests and previews to ensure consistent, reproducible results.
- **Flexible Response Modification**: Dynamically override JSON key-value pairs to simulate different states or conditions using the same recording.
- **Request Interception**: Intercept and optionally modify requests based on URL keywords for enhanced testing and preview scenarios without constant server calls.

## Workflow

1. **Initial Setup and Recording**:  
   - Run your unit test or SwiftUI preview with `isRecordingEnabled = true`.  
   - Relay records all intercepted network requests and their responses.

2. **Subsequent Uses with Recorded Data**:  
   - Turn off recording (`isRecordingEnabled = false`).  
   - Relay now uses the previously recorded responses from the file system, ensuring no live server calls.

3. **Manipulating Recorded Results**:  
   - Use `jsonValueOverrides` to modify parts of the recorded response dynamically, simulating different states without needing new recordings.

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
  - `true`: Capture and store responses during the initial run.  
  - `false`: Subsequent runs use recorded data, ensuring no live server calls.
- **`urlKeywords`**: Filter requests by URL keywords.
- **`jsonValueOverrides`**: A dictionary of keys and their override values to manipulate responses.

**Recording Folder Structure:**

- **`recordingRootFolder`**: Automatically detected based on the file invoking `recordAndReplay`, with all recordings stored under a `__RelayRecords__` folder.
- **`recordingFolder`**: Defaults to the function name from which `recordAndReplay` was called, making it easy to identify which tests generated which recordings.

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
   Call `recordAndReplay` or `interceptAndModify` **before** creating your custom `URLSession`.

2. **Manually Set `protocolClasses`**:  
   If the session is already created, manually set `protocolClasses` to include `RelayURLProtocol`:

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
