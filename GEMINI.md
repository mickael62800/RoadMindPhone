# GEMINI.md

## Project Overview

This is a Flutter application named `roadmindphone`, designed for managing projects and recording sessions. It captures GPS data (latitude, longitude, speed, heading, timestamp, and video timestamp) and video during sessions. The project is configured for Android, iOS, Linux, macOS, Web, and Windows.

**Key Technologies:**

*   **Language:** Dart
*   **Framework:** Flutter
*   **Dependencies:**
    *   `flutter`: The core Flutter SDK.
    *   `cupertino_icons`: For iOS-style icons.
    *   `geolocator`: For GPS data collection.
    *   `camera`: For video recording.
*   **Development Dependencies:**
    *   `flutter_test`: For widget testing.
    *   `flutter_lints`: For code linting.

## Building and Running

*   **Run the application:**
    ```bash
    flutter run
    ```
*   **Run tests:**
    ```bash
    flutter test
    ```

## Development Conventions

*   **Coding Style:** The project uses the recommended linting rules from the `flutter_lints` package, as configured in `analysis_options.yaml`.
*   **Testing:** Widget tests are located in the `test/` directory. The existing `test/widget_test.dart` file provides a basic example of a widget test.
