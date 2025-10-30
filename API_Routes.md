# RoadMind API Routes Documentation

This document outlines the available API routes for managing Projects, including their associated Sessions and GPS Points.

## Base URL

The base URL for all Project-related endpoints is `/api/Projects`.

---

## 1. Create a New Project with Sessions and Videos

**HTTP Method:** `POST`
**Route:** `/api/Projects`
**Description:** Creates a new project, including its associated sessions and allows for uploading video files for each session.

**Request Type:** `multipart/form-data`

**Request Body:**
The request body must be `multipart/form-data` and contain the following parts:

*   **`ProjectData` (Form Field - JSON String):**
    A JSON string representing the `CreateProjectDto`. This DTO contains the project's basic information and a list of sessions. Each session in this list should have a temporary `Id` (e.g., `1`, `2`) that will be used to link it to its corresponding video file.

    ```json
    {
      "name": "New Project Title",
      "description": "Description of the new project.",
      "sessions": [
        {
          "id": 1, // Temporary ID to link with video file
          "name": "Session Alpha",
          "startTime": "2023-10-27T10:00:00Z",
          "endTime": "2023-10-27T11:00:00Z",
          "notes": "First session notes.",
          "videoPath": null, // This will be filled by the API
          "gpsPoints": [
            {
              "latitude": 48.8566,
              "longitude": 2.3522,
              "altitude": 10.5,
              "speed": 50.2,
              "heading": 90.0,
              "timestamp": "2023-10-27T10:00:05Z",
              "videoTimestampMs": 5000
            }
          ]
        },
        {
          "id": 2, // Temporary ID to link with video file
          "name": "Session Beta",
          "startTime": "2023-10-27T14:00:00Z",
          "endTime": "2023-10-27T15:00:00Z",
          "notes": "Second session notes.",
          "videoPath": null,
          "gpsPoints": []
        }
      ]
    }
    ```

*   **`sessionVideo_{sessionId}` (Form Field - File):**
    For each session that has a video, include a file field named `sessionVideo_X`, where `X` corresponds to the temporary `id` of the session in the `ProjectData` JSON. The value of this field should be the actual video file (`IFormFile`).

    Example: If `Session Alpha` has `id: 1`, its video file field should be named `sessionVideo_1`.

**Responses:**
*   `201 Created`: Returns the created `ProjectDto` object.
*   `400 Bad Request`: If the input data is invalid or deserialization fails.

---

## 2. Get Project with Sessions and GPS Points

**HTTP Method:** `GET`
**Route:** `/api/Projects/{id}`
**Description:** Retrieves a specific project by its ID, including all its associated sessions and their GPS points.

**URL Parameters:**
*   `id` (integer, required): The unique identifier of the project.

**Responses:**
*   `200 OK`: Returns the `ProjectDto` object, including nested `SessionDto` and `SessionGpsPointDto` collections.
*   `404 Not Found`: If no project with the specified ID is found.

---

## 3. Update an Existing Project with Sessions and Videos

**HTTP Method:** `PUT`
**Route:** `/api/Projects/{id}`
**Description:** Updates an existing project identified by `id`. This endpoint allows for updating project details, and synchronizing its associated sessions and their GPS points, including uploading new video files or replacing existing ones.

**Request Type:** `multipart/form-data`

**URL Parameters:**
*   `id` (integer, required): The unique identifier of the project to update. This `id` must match the `Id` property within the `ProjectData` JSON.

**Request Body:**
The request body must be `multipart/form-data` and contain the following parts:

*   **`ProjectData` (Form Field - JSON String):**
    A JSON string representing the `UpdateProjectDto`. This DTO contains the project's updated information and a list of sessions. Each session in this list should have its actual `Id` if it's an existing session, or a temporary `Id` (e.g., `1`, `2`) if it's a new session being added to the project. The temporary `Id` is used to link it to its corresponding video file.

    ```json
    {
      "id": 123, // Actual ID of the project being updated
      "name": "Updated Project Title",
      "description": "Updated description of the project.",
      "sessions": [
        {
          "id": 456, // Actual ID of an existing session
          "projectId": 123,
          "name": "Updated Session Alpha",
          "startTime": "2023-10-27T10:00:00Z",
          "endTime": "2023-10-27T11:30:00Z",
          "notes": "Updated notes for the first session.",
          "videoPath": "/path/to/existing/video.mp4", // Keep existing path or set to null if no new video
          "gpsPoints": [
            {
              "id": 789, // Actual ID of an existing GPS point
              "sessionId": 456,
              "latitude": 48.8567,
              "longitude": 2.3523,
              "altitude": 11.0,
              "speed": 55.0,
              "heading": 95.0,
              "timestamp": "2023-10-27T10:00:10Z",
              "videoTimestampMs": 10000
            },
            {
              "id": 0, // New GPS point (Id=0 or not set for new entities)
              "sessionId": 456,
              "latitude": 48.8568,
              "longitude": 2.3524,
              "altitude": 11.5,
              "speed": 56.0,
              "heading": 96.0,
              "timestamp": "2023-10-27T10:00:15Z",
              "videoTimestampMs": 15000
            }
          ]
        },
        {
          "id": 3, // Temporary ID for a new session being added to the project
          "projectId": 123,
          "name": "New Session Gamma",
          "startTime": "2023-10-28T09:00:00Z",
          "endTime": "2023-10-28T10:00:00Z",
          "notes": "A brand new session.",
          "videoPath": null,
          "gpsPoints": []
        }
      ]
    }
    ```

*   **`sessionVideo_{sessionId}` (Form Field - File):**
    For each session that has a new or updated video, include a file field named `sessionVideo_X`, where `X` corresponds to the `id` of the session in the `ProjectData` JSON (either its actual ID for existing sessions, or its temporary ID for new sessions). The value of this field should be the actual video file (`IFormFile`).

    Example: If `Session Alpha` has `id: 456`, its new video file field should be named `sessionVideo_456`. If `New Session Gamma` has `id: 3`, its video file field should be named `sessionVideo_3`.

**Responses:**
*   `200 OK`: Returns the updated `ProjectDto` object.
*   `400 Bad Request`: If the input data is invalid, `id` in URL does not match `id` in body, or deserialization fails.
*   `404 Not Found`: If no project with the specified ID is found.

---

## 4. Check Project Existence

**HTTP Method:** `HEAD`
**Route:** `/api/Projects/{id}`
**Description:** Checks if a project with the specified ID exists without returning the full resource data.

**URL Parameters:**
*   `id` (integer, required): The unique identifier of the project.

**Responses:**
*   `200 OK`: If a project with the specified ID exists.
*   `404 Not Found`: If no project with the specified ID is found.
