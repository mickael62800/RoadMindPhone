# android/GEMINI.md

This directory contains the Android-specific project files for the `roadmindphone` Flutter application.

## Key Configurations:

*   **Plugins:** Uses `com.android.application` and `kotlin-android` Gradle plugins.
*   **Namespace:** The Android application namespace is `com.example.roadmindphone`.
*   **SDK Versions:** `compileSdk`, `minSdk`, and `targetSdk` are managed by the Flutter build system.
*   **Java Version:** Configured to use Java 11.
*   **Flutter Integration:** The Flutter module is integrated from the parent directory (`../..`).

## Building and Running:

To build and run the Android application, use the standard Flutter commands from the project root:

```bash
flutter run
```

Alternatively, you can open the `android` directory in Android Studio for native development and debugging.
