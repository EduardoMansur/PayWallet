# PayWallet

A mobile payment application built with SwiftUI following the MVVM architecture pattern.

## Table of Contents
- [Requirements](#requirements)
- [Getting Started](#getting-started)
  - [Running on Simulator](#running-on-simulator)
  - [Running on Physical Device](#running-on-physical-device)
- [Running Tests](#running-tests)
  - [Run All Tests](#run-all-tests)
  - [Run Specific Test Suite](#run-specific-test-suite)
  - [Customizing Mock Responses](#customizing-mock-responses)
- [Dependencies](#dependencies)
- [Architecture](#architecture)
  - [Design Decisions](#design-decisions)
  - [Modular Structure](#modular-structure)
- [Special Behaviors](#special-behaviors)
  - [403 Exception Scenario](#403-exception-scenario)
  - [Transaction Notifications](#transaction-notifications)

## Requirements

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### Running on Simulator

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd PayWallet
   ```

2. Open the project in Xcode:
   ```bash
   open PayWallet.xcodeproj
   ```

3. Select a simulator from the device dropdown menu (e.g., iPhone 15 Pro)

4. Build and run the project:
   - Press `Cmd + R`, or
   - Click the play button in Xcode's toolbar

### Running on Physical Device

1. Connect your iOS device to your Mac via USB

2. Open the project in Xcode

3. Select your device from the device dropdown menu

4. Configure code signing:
   - Select the PayWallet target in the project navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team
   - Ensure "Automatically manage signing" is checked

5. Build and run the project:
   - Press `Cmd + R`, or
   - Click the play button in Xcode's toolbar

6. If this is your first time running the app on the device:
   - On your device, go to Settings > General > VPN & Device Management
   - Trust your development certificate

## Running Tests

### Run All Tests

**Using Xcode:**
- Press `Cmd + U`, or
- Navigate to Product > Test in the menu bar

**Using Command Line:**
```bash
xcodebuild test -scheme PayWallet -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Run Specific Test Suite

```bash
# Run main app tests
xcodebuild test -scheme PayWallet -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run NetworkLayer module tests
cd NetworkLayer
swift test

# Run DesignSystem module tests
cd DesignSystem
swift test
```

**Using Xcode:**
1. Open the Test Navigator (`Cmd + 6`)
2. Click the play button next to:
   - Individual test methods
   - Test classes
   - Test targets
   - Or the entire test bundle

### Customizing Mock Responses

The application uses mock services for development and testing without requiring a real backend server. These mocks are implemented using `URLProtocol` to intercept network requests and return predefined responses.

#### Available Mock Services

Each service in the `PayWallet/Services/` folder has a corresponding mock implementation:

- `MockAuthService` with `MockURLProtocol` - Handles authentication requests
- `MockTransferService` with `TransferMockURLProtocol` - Handles transfer requests
- Additional mock services for profiles, contacts, etc.

#### How Mock Services Work

Mock services use `URLProtocol` subclasses to intercept network requests. When a request is made:
1. The URLProtocol intercepts the request before it reaches the network
2. It examines the request URL, headers, and body
3. It returns a predefined response based on the request parameters
4. The response is delivered to the app as if it came from a real server

#### Customizing Mock Behavior

**Location:** `PayWallet/Services/`

**Example 1: Modifying Login Credentials**

To change the accepted login credentials, edit `AuthService.swift`:

```swift
// File: PayWallet/Services/AuthService.swift
// Location: MockURLProtocol.handleLoginRequest() method (line 262)

private func handleLoginRequest() {
    // ... existing code ...

    // Change these values to accept different credentials:
    if credentials.email == "test@paywallet.com" && credentials.password == "password123" {
        let response = LoginResponse(
            token: "mock_token_\(UUID().uuidString)",
            userId: "user_123",
            email: credentials.email
        )
        sendSuccess(response: response)
    } else {
        sendUnauthorized()
    }
}
```

**To customize:**
- Change `test@paywallet.com` to your desired test email
- Change `password123` to your desired test password
- Modify the `userId` or other response fields

**Example 2: Changing the 403 Transfer Amount Behavior**

To modify or remove the 403 exception, edit `TransferService.swift`:

```swift
// File: PayWallet/Services/TransferService.swift
// Location: TransferMockURLProtocol.handleTransferAuthorizationRequest() method (line 224)

// Simulate authorization failure for amount equal to 403
if transferRequest.amount == 403 {
    let response = TransferAuthorizationResponse(
        authorized: false,
        message: "Transaction declined. This amount cannot be processed at this time."
    )
    sendSuccess(response: response)
} else {
    let response = TransferAuthorizationResponse(
        authorized: true,
        message: "Transfer authorized successfully"
    )
    sendSuccess(response: response)
}
```

**To customize:**
- Change `403` to a different amount (e.g., `500`, `999.99`)
- Modify the decline message
- Add additional conditions (e.g., decline amounts over 1000)
- Remove the condition entirely to accept all amounts

**Example 3: Adjusting Network Delay**

Each mock has a simulated network delay. To make the app respond faster or slower:

```swift
// File: PayWallet/Services/AuthService.swift
// Location: MockURLProtocol.startLoading() method (line 234)

try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds

// Change to:
try await Task.sleep(nanoseconds: 500_000_000)   // 0.5 seconds (faster)
// or
try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds (slower)
```

**Example 4: Adding Custom Response Data**

To return different user profiles, contact lists, or balances:

```swift
// In the appropriate mock URLProtocol handler
let customResponse = YourResponseType(
    field1: "custom value",
    field2: 12345
)
sendSuccess(response: customResponse)
```

#### Common Customization Scenarios

**1. Test with different user data:**
Modify the response objects in the `sendSuccess()` calls to return different:
- User names, IDs, or emails
- Account balances
- Contact lists
- Transaction histories

**2. Test error scenarios:**
Replace `sendSuccess()` with `sendUnauthorized()` or `sendError()` to simulate:
- Network failures
- Authentication errors
- Server errors

**3. Test edge cases:**
Add conditional logic to the handler methods to simulate:
- Rate limiting
- Insufficient balance
- Invalid input
- Concurrent requests

#### Switching Between Mock and Real Services

The app is configured to use mock services by default. To switch to real API services:

1. Replace `MockAuthService()` with `AuthService()` in your dependency injection setup
2. Replace `MockTransferService()` with `TransferService()` in your dependency injection setup
3. Configure the real API base URL in the service request structs (currently `https://api.paywallet.com`)

**Note:** Mock services are only used when running the app in development. Tests use dedicated test mocks from `PayWalletTests/Mocks/` which provide more granular control for unit testing.

## Dependencies

This project uses Swift Package Manager (SPM) for dependency management.

### Main App Dependencies

- **NetworkLayer** (Local Package): Custom networking layer for API communication
- **DesignSystem** (Local Package): Reusable UI components and design tokens
- **swift-dependencies**: Dependency injection framework for testing and modularity

### Module Dependencies

**NetworkLayer** (`Package.swift`)
- Swift Tools Version: 5.9
- Platforms: iOS 15.0+, macOS 12.0+, tvOS 15.0+, watchOS 8.0+
- No external dependencies

**DesignSystem** (`Package.swift`)
- Swift Tools Version: 6.2
- Platforms: iOS 15.0+, macOS 12.0+
- No external dependencies

## Architecture

### Design Decisions

#### MVVM Pattern
The application follows the **Model-View-ViewModel (MVVM)** architectural pattern as a project requirement. This pattern provides:
- Clear separation of concerns
- Improved testability through view model isolation
- Better maintainability and scalability
- Natural integration with SwiftUI's declarative syntax

#### Modular Architecture

The project is structured with separate Swift Package Manager modules to improve code organization, testability, and reusability:

**1. DesignSystem Module**
- Contains all reusable UI components, colors, typography, and design tokens
- Can be tested independently from the main application
- Reusable across multiple projects
- Ensures consistent design language throughout the app
- Provides a centralized location for UI/UX updates

**2. NetworkLayer Module**
- Encapsulates all networking logic and API communication
- Provides a clean abstraction over network requests
- Can be tested in isolation with mock responses
- Portable to other projects requiring similar networking capabilities
- Handles request/response serialization and error mapping

**3. Future Modularity**
Additional modules can be created as the project grows:
- **Metrics Module**: Analytics and performance tracking SPM for monitoring user behavior and app performance
- **Core Module**: Shared utilities, extensions, and common business logic that can be reused across features
- **Authentication Module**: Dedicated module for user authentication and session management
- **Storage Module**: Local data persistence and caching layer

This modular approach provides several benefits:
- **Faster compilation times** through incremental builds
- **Better dependency management** with clear module boundaries
- **Easier unit testing** with isolated, testable components
- **Code reusability** across multiple projects
- **Team scalability** - different teams can own different modules
- **Independent versioning** and deployment of modules
- **Reduced coupling** between different parts of the application

### Project Structure

```
PayWallet/
├── PayWallet/              # Main app target
│   ├── Features/           # Feature modules (Login, Home, Transfer)
│   ├── Core/               # Core app logic and utilities
│   └── Services/           # App-level services (with mock implementations)
├── DesignSystem/           # UI components SPM
│   ├── Sources/            # Design system components
│   └── Tests/              # Design system tests
├── NetworkLayer/           # Networking SPM
│   ├── Sources/            # Network client and models
│   └── Tests/              # Network layer tests
├── PayWalletTests/         # Unit tests
│   ├── Mocks/              # Test mocks and stubs
│   └── ViewModels/         # ViewModel tests
└── PayWalletUITests/       # UI automation tests
```

## Special Behaviors

### 403 Exception Scenario

The application includes special handling for a specific edge case:

When a user attempts to transfer exactly **403** as the transfer amount, the application treats this as an exception scenario. This behavior was implemented to demonstrate error handling and validation logic.

**Behavior:**
- Input value: `403`
- Result: The transfer authorization will be declined
- Server response: `authorized: false` with message "Transaction declined. This amount cannot be processed at this time."
- UI feedback: Error alert is shown with the decline message

**Purpose:**
- Demonstrates custom server-side validation
- Shows proper error handling for declined transactions
- Example of business rule enforcement at the API level
- Tests edge case handling in the transfer flow

**Implementation:**
The exception is implemented in the mock transfer service at:
```
PayWallet/Services/TransferService.swift:224
```

**Testing:**
See test case in `TransferViewModelTests.swift:230` - `testConfirmTransfer_NotAuthorized_ShowsErrorMessage()`

**Customization:**
To change this behavior, edit the `handleTransferAuthorizationRequest()` method in `TransferMockURLProtocol`. See [Customizing Mock Responses](#customizing-mock-responses) for details.

### Transaction Notifications

The application provides user feedback through the iOS notification system:

**Successful Transaction Notification:**
- A local notification is triggered automatically when a transaction completes successfully
- Users receive immediate feedback even if the app is in the background or closed
- The notification includes:
  - Transfer amount (formatted as currency)
  - Recipient name
  - Success confirmation message

**Requirements:**
- Users must grant notification permissions when first launching the app
- The app requests notification authorization on first use
- Notifications can be managed in iOS Settings > PayWallet > Notifications

**Implementation Details:**
- Uses iOS `UserNotifications` framework
- Notifications are **local** (no remote push notification server required)
- Triggered only on successful, authorized transfers
- Not sent if transfer is declined or encounters an error
- Follows iOS best practices for user engagement and privacy

**Example Notification:**
```
PayWallet
Transfer Successful
Sent $250.50 to Alice Johnson
```

**Testing:**
The notification behavior is tested using `NotificationManagerMock` in the test suite.
See: `TransferViewModelTests.swift:190` - `testConfirmTransfer_Success_SendsNotificationAndMarksSuccess()`

**Implementation:**
Notification service located at:
```
PayWallet/Services/NotificationManager.swift
```
