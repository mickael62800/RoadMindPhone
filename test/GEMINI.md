# test/GEMINI.md

This directory contains the unit and widget tests for the `roadmindphone` Flutter application.

## Testing Framework:

*   **flutter_test:** The primary testing framework provided by Flutter for unit and widget testing.

## Running Tests:

To run all tests in the project, execute the following command from the project root:

```bash
flutter test
```

## Writing Tests:

*   Widget tests typically involve building a widget, interacting with it using a `WidgetTester`, and then verifying its state or appearance using `expect` matchers.
*   New test files should be created within this directory, following a naming convention like `[feature_name]_test.dart`.
