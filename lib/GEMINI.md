# lib/GEMINI.md

This directory contains the core Dart source code for the `roadmindphone` Flutter application.

## Key Files:

*   `main.dart`: The application's entry point. It initializes the Flutter app, sets up the database for desktop platforms, defines the main `MyApp` widget, and the `MyHomePage` widget which displays a list of projects.
*   `database_helper.dart`: Handles database operations for the application, such as creating, reading, updating, and deleting projects and sessions.
*   `project_index_page.dart`: Displays the details or sessions related to a specific project.
*   `session_completion_page.dart`: Handles the completion of a session, including video recording and GPS data collection (latitude, longitude, speed, heading, timestamp, and video timestamp).
*   `session_index_page.dart`: Displays a list of sessions for a project.
*   `export_data_page.dart`: Handles the export of session data.
*   `settings_page.dart`: Manages application settings.

## Application Flow:

1.  `main.dart` is executed, setting up the Flutter application and database.
2.  The initial screen displays a list of projects.
3.  Users can add new projects.
4.  Tapping on a project navigates to `ProjectIndexPage`, displaying details or sessions for that project.
5.  From `ProjectIndexPage`, users can start a new session, which involves video recording and GPS data collection via `SessionCompletionPage`.
6.  Completed sessions are saved, and their data can be viewed or exported.

**Backend Connection:**
The application connects to a backend API for managing projects and sessions. The API endpoints are configured to use `http://192.168.1.10:5160`. Ensure the backend server is running and accessible at this address and port.
