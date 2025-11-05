# 🛣️ RoadMind API - Routes Documentation

**Version:** 1.0.0  
**Base URL:** `http://localhost:8080/api`  
**Date:** 3 novembre 2025

---

## 📋 Table des Matières

1. [Projects](#-1-projects)
2. [Sessions](#-2-sessions)
3. [GPS Points](#-3-gps-points)
4. [Health Checks](#-4-health-checks)
5. [Cache Management](#-5-cache-management)
6. [DTOs & Models](#-dtos--models)

---

## 🗂️ 1. Projects

### 1.1 Get All Projects

```http
GET /api/projects
```

**Description:** Récupère tous les projets avec leurs sessions et points GPS.

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "name": "Projet Route Nationale",
    "description": "Inspection de la RN7",
    "createdAt": "2025-11-02T10:00:00Z",
    "updatedAt": "2025-11-02T10:00:00Z",
    "sessions": [
      {
        "id": 1,
        "name": "Session 1",
        "videoPath": "/uploads/videos/session1.mp4",
        "createdAt": "2025-11-02T10:00:00Z"
      }
    ]
  }
]
```

---

### 1.2 Get Project By ID

```http
GET /api/projects/{id}
```

**Path Parameters:**

- `id` (integer, required) - ID du projet

**Response:** `200 OK`

```json
{
  "id": 1,
  "name": "Projet Route Nationale",
  "description": "Inspection de la RN7",
  "createdAt": "2025-11-02T10:00:00Z",
  "updatedAt": "2025-11-02T10:00:00Z",
  "sessions": [...]
}
```

**Error Responses:**

- `404 Not Found` - Projet non trouvé

---

### 1.3 Create Project (Multipart/Form-Data)

```http
POST /api/projects
Content-Type: multipart/form-data
```

**Request Body (Form-Data):**

- `ProjectData` (string, required) - JSON stringifié du CreateProjectDto
- `SessionVideos` (file[], optional) - Fichiers vidéo des sessions

**ProjectData JSON:**

```json
{
  "name": "Nouveau Projet",
  "description": "Description optionnelle",
  "sessions": [
    {
      "name": "Session 1",
      "createdAt": "2025-11-02T10:00:00Z"
    }
  ]
}
```

**Example (curl):**

```bash
curl -X POST http://localhost:8080/api/projects \
  -F "ProjectData={\"name\":\"Test Project\",\"sessions\":[{\"name\":\"Session 1\"}]}" \
  -F "SessionVideos=@/path/to/video1.mp4" \
  -F "SessionVideos=@/path/to/video2.mp4"
```

**Response:** `201 Created`

```json
{
  "id": 1,
  "name": "Nouveau Projet",
  "description": "Description optionnelle",
  "createdAt": "2025-11-02T10:00:00Z",
  "updatedAt": "2025-11-02T10:00:00Z",
  "sessions": [...]
}
```

**Headers:**

- `Location: /api/projects/1`

**Error Responses:**

- `400 Bad Request` - Données invalides

---

### 1.4 Create Project (JSON)

```http
POST /api/projects
Content-Type: application/json
```

**Request Body:**

```json
{
  "name": "Nouveau Projet",
  "description": "Description optionnelle",
  "sessions": [
    {
      "name": "Session 1",
      "createdAt": "2025-11-02T10:00:00Z"
    }
  ]
}
```

**Required Fields:**

- `name` (string) - Nom du projet

**Optional Fields:**

- `description` (string) - Description du projet
- `sessions` (array) - Liste des sessions à créer

**Response:** `201 Created`

---

### 1.5 Update Project (Multipart/Form-Data)

```http
PUT /api/projects/{id}
Content-Type: multipart/form-data
```

**Path Parameters:**

- `id` (integer, required) - ID du projet à modifier

**Request Body (Form-Data):**

- `ProjectData` (string, required) - JSON stringifié du UpdateProjectDto
- `SessionVideos` (file[], optional) - Nouveaux fichiers vidéo

**ProjectData JSON:**

```json
{
  "id": 1,
  "name": "Projet Modifié",
  "description": "Nouvelle description",
  "sessions": [...]
}
```

**Response:** `200 OK`

**Error Responses:**

- `400 Bad Request` - ID mismatch ou données invalides
- `404 Not Found` - Projet non trouvé

---

### 1.6 Update Project (JSON)

```http
PUT /api/projects/{id}
Content-Type: application/json
```

**Request Body:**

```json
{
  "id": 1,
  "name": "Projet Modifié",
  "description": "Nouvelle description",
  "sessions": [...]
}
```

**Response:** `200 OK`

---

### 1.7 Check Project Exists

```http
HEAD /api/projects/{id}
```

**Path Parameters:**

- `id` (integer, required) - ID du projet

**Response:**

- `200 OK` - Le projet existe
- `404 Not Found` - Le projet n'existe pas

**Note:** Pas de body dans la réponse (méthode HEAD)

---

## 🎬 2. Sessions

**Base URL:** `/api/projects/{projectId}/sessions`

### 2.1 Get Sessions By Project

```http
GET /api/projects/{projectId}/sessions
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "projectId": 1,
    "name": "Session Matinale",
    "videoPath": "/uploads/videos/session1.mp4",
    "createdAt": "2025-11-02T08:00:00Z",
    "updatedAt": "2025-11-02T08:00:00Z"
  }
]
```

**Error Responses:**

- `404 Not Found` - Projet non trouvé

---

### 2.2 Get Session By ID

```http
GET /api/projects/{projectId}/sessions/{sessionId}
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session

**Response:** `200 OK`

```json
{
  "id": 1,
  "projectId": 1,
  "name": "Session Matinale",
  "videoPath": "/uploads/videos/session1.mp4",
  "createdAt": "2025-11-02T08:00:00Z",
  "updatedAt": "2025-11-02T08:00:00Z"
}
```

**Error Responses:**

- `404 Not Found` - Projet ou session non trouvé

---

### 2.3 Create Session

```http
POST /api/projects/{projectId}/sessions
Content-Type: application/json
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet

**Request Body:**

```json
{
  "name": "Nouvelle Session",
  "videoPath": "/uploads/videos/session.mp4",
  "createdAt": "2025-11-02T10:00:00Z"
}
```

**Required Fields:**

- `name` (string) - Nom de la session

**Optional Fields:**

- `videoPath` (string) - Chemin vers la vidéo
- `createdAt` (datetime) - Date de création (auto si omis)

**Response:** `201 Created`

```json
{
  "id": 2,
  "projectId": 1,
  "name": "Nouvelle Session",
  "videoPath": "/uploads/videos/session.mp4",
  "createdAt": "2025-11-02T10:00:00Z",
  "updatedAt": "2025-11-02T10:00:00Z"
}
```

**Headers:**

- `Location: /api/projects/1/sessions/2`

**Error Responses:**

- `400 Bad Request` - Données invalides
- `404 Not Found` - Projet non trouvé

---

### 2.4 Update Session

```http
PUT /api/projects/{projectId}/sessions/{sessionId}
Content-Type: application/json
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session

**Request Body:**

```json
{
  "id": 1,
  "name": "Session Modifiée",
  "videoPath": "/uploads/videos/new_video.mp4"
}
```

**Response:** `204 No Content`

**Error Responses:**

- `400 Bad Request` - ID mismatch ou données invalides
- `404 Not Found` - Projet ou session non trouvé

---

### 2.5 Delete Session

```http
DELETE /api/projects/{projectId}/sessions/{sessionId}
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session

**Response:** `204 No Content`

**Error Responses:**

- `404 Not Found` - Projet ou session non trouvé

---

## 📍 3. GPS Points

**Base URL:** `/api/projects/{projectId}/sessions/{sessionId}/gpspoints`

### 3.1 Get GPS Points (Paginated)

```http
GET /api/projects/{projectId}/sessions/{sessionId}/gpspoints?pageNumber=1&pageSize=50
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session

**Query Parameters:**

- `pageNumber` (integer, optional, default: 1) - Numéro de page (1-based)
- `pageSize` (integer, optional, default: 50, max: 1000) - Nombre d'éléments par page

**Response:** `200 OK`

```json
{
  "items": [
    {
      "id": 1,
      "sessionId": 1,
      "latitude": 48.8566,
      "longitude": 2.3522,
      "altitude": 35.0,
      "speed": 50.5,
      "timestamp": "2025-11-02T10:15:30Z"
    }
  ],
  "totalCount": 1500,
  "pageNumber": 1,
  "pageSize": 50,
  "totalPages": 30,
  "hasPreviousPage": false,
  "hasNextPage": true
}
```

**Error Responses:**

- `404 Not Found` - Projet ou session non trouvé

---

### 3.2 Get Session Statistics

```http
GET /api/projects/{projectId}/sessions/{sessionId}/gpspoints/statistics
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session

**Description:** Calcule les statistiques de la session basées sur les points GPS.

**Response:** `200 OK`

```json
{
  "sessionId": 1,
  "totalDistanceMeters": 45230.5,
  "durationSeconds": 3600,
  "averageSpeedKmh": 45.2,
  "maxSpeedKmh": 78.5,
  "gpsPointCount": 1500
}
```

**Statistics Calculation:**

- `totalDistanceMeters` - Distance totale calculée via formule de Haversine
- `durationSeconds` - Durée entre premier et dernier point GPS
- `averageSpeedKmh` - Moyenne des vitesses (valeurs non-null uniquement)
- `maxSpeedKmh` - Vitesse maximale enregistrée
- `gpsPointCount` - Nombre total de points GPS

**Error Responses:**

- `404 Not Found` - Session non trouvée ou sans points GPS

---

### 3.3 Get GPS Point By ID

```http
GET /api/projects/{projectId}/sessions/{sessionId}/gpspoints/{gpsPointId}
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session
- `gpsPointId` (integer, required) - ID du point GPS

**Response:** `200 OK`

```json
{
  "id": 1,
  "sessionId": 1,
  "latitude": 48.8566,
  "longitude": 2.3522,
  "altitude": 35.0,
  "speed": 50.5,
  "timestamp": "2025-11-02T10:15:30Z"
}
```

**Error Responses:**

- `404 Not Found` - Point GPS non trouvé

---

### 3.4 Create GPS Point

```http
POST /api/projects/{projectId}/sessions/{sessionId}/gpspoints
Content-Type: application/json
```

**Path Parameters:**

- `projectId` (integer, required) - ID du projet
- `sessionId` (integer, required) - ID de la session

**Request Body:**

```json
{
  "latitude": 48.8566,
  "longitude": 2.3522,
  "altitude": 35.0,
  "speed": 50.5,
  "timestamp": "2025-11-02T10:15:30Z"
}
```

**Required Fields:**

- `latitude` (double) - Latitude (-90 à 90)
- `longitude` (double) - Longitude (-180 à 180)
- `timestamp` (datetime) - Horodatage du point

**Optional Fields:**

- `altitude` (double, nullable) - Altitude en mètres
- `speed` (double, nullable) - Vitesse en km/h

**Validation Rules:**

- Latitude: -90 ≤ lat ≤ 90
- Longitude: -180 ≤ lon ≤ 180
- Speed: ≥ 0 (si fourni)
- Altitude: ≥ -500 (si fourni)

**Response:** `201 Created`

```json
{
  "id": 1501,
  "sessionId": 1,
  "latitude": 48.8566,
  "longitude": 2.3522,
  "altitude": 35.0,
  "speed": 50.5,
  "timestamp": "2025-11-02T10:15:30Z"
}
```

**Headers:**

- `Location: /api/projects/1/sessions/1/gpspoints/1501`

**Error Responses:**

- `400 Bad Request` - Données invalides
- `404 Not Found` - Session non trouvée

---

### 3.5 Update GPS Point

```http
PUT /api/projects/{projectId}/sessions/{sessionId}/gpspoints/{gpsPointId}
Content-Type: application/json
```

**Path Parameters:**

- `projectId` (integer, required)
- `sessionId` (integer, required)
- `gpsPointId` (integer, required)

**Request Body:**

```json
{
  "latitude": 48.857,
  "longitude": 2.3525,
  "altitude": 36.0,
  "speed": 51.0,
  "timestamp": "2025-11-02T10:15:30Z"
}
```

**Response:** `204 No Content`

**Error Responses:**

- `404 Not Found` - Point GPS non trouvé

---

### 3.6 Delete GPS Point

```http
DELETE /api/projects/{projectId}/sessions/{sessionId}/gpspoints/{gpsPointId}
```

**Path Parameters:**

- `projectId` (integer, required)
- `sessionId` (integer, required)
- `gpsPointId` (integer, required)

**Response:** `204 No Content`

**Error Responses:**

- `404 Not Found` - Point GPS non trouvé

---

## 🏥 4. Health Checks

### 4.1 Simple Health Check

```http
GET /api/health
```

**Description:** Health check simple pour vérifier que l'API répond.

**Response:** `200 OK`

```json
{
  "status": "Healthy",
  "timestamp": "2025-11-02T10:00:00Z",
  "service": "RoadMind API"
}
```

**Use Case:** Utilisé par Docker HEALTHCHECK et orchestrateurs (Kubernetes, Docker Compose)

---

### 4.2 Detailed Health Check

```http
GET /api/health/detailed
```

**Description:** Health check détaillé avec vérification des dépendances (PostgreSQL, Redis).

**Response:** `200 OK` (si tout est sain)

```json
{
  "status": "Healthy",
  "timestamp": "2025-11-02T10:00:00Z",
  "duration": 45.2,
  "checks": [
    {
      "name": "database",
      "status": "Healthy",
      "duration": 12.5,
      "description": "PostgreSQL connection is healthy",
      "error": null
    },
    {
      "name": "redis",
      "status": "Healthy",
      "duration": 8.3,
      "description": "Redis connection is healthy",
      "error": null
    }
  ]
}
```

**Response:** `503 Service Unavailable` (si un service est down)

```json
{
  "status": "Unhealthy",
  "timestamp": "2025-11-02T10:00:00Z",
  "duration": 5002.1,
  "checks": [
    {
      "name": "database",
      "status": "Unhealthy",
      "duration": 5000.0,
      "description": "Database connection timeout",
      "error": "Npgsql.NpgsqlException: Connection timeout"
    }
  ]
}
```

---

## 💾 5. Cache Management

### 5.1 Get Cache Statistics

```http
GET /api/cache/stats
```

**Description:** Récupère les statistiques du cache Redis.

**Response:** `200 OK`

```json
{
  "totalHits": 15420,
  "totalMisses": 1830,
  "totalInvalidations": 45,
  "totalRequests": 17250,
  "hitRatePercentage": 89.39,
  "missRatePercentage": 10.61,
  "uptimeDays": 2,
  "uptimeHours": 14,
  "uptimeMinutes": 35,
  "uptimeSeconds": 42,
  "startTime": "2025-10-31T20:00:00Z"
}
```

**Metrics Explanation:**

- `totalHits` - Nombre de requêtes servies depuis le cache
- `totalMisses` - Nombre de requêtes nécessitant une requête DB
- `totalInvalidations` - Nombre d'invalidations de cache
- `hitRatePercentage` - Taux de succès du cache (%)
- `missRatePercentage` - Taux d'échec du cache (%)

---

### 5.2 Reset Cache Statistics

```http
POST /api/cache/stats/reset
```

**Description:** Réinitialise les compteurs de statistiques du cache.

**Response:** `200 OK`

```json
{
  "message": "Cache statistics reset successfully"
}
```

**Note:** Ne vide pas le cache, réinitialise uniquement les compteurs.

---

## 📦 DTOs & Models

### ProjectDto

```json
{
  "id": 1,
  "name": "string (required)",
  "description": "string (nullable)",
  "createdAt": "datetime",
  "updatedAt": "datetime",
  "sessions": [SessionDto]
}
```

### SessionDto

```json
{
  "id": 1,
  "projectId": 1,
  "name": "string (required)",
  "videoPath": "string (nullable)",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### SessionGpsPointDto

```json
{
  "id": 1,
  "sessionId": 1,
  "latitude": "double (required, -90 to 90)",
  "longitude": "double (required, -180 to 180)",
  "altitude": "double (nullable, >= -500)",
  "speed": "double (nullable, >= 0)",
  "timestamp": "datetime (required)"
}
```

### PaginatedResult<T>

```json
{
  "items": [T],
  "totalCount": "integer",
  "pageNumber": "integer",
  "pageSize": "integer",
  "totalPages": "integer",
  "hasPreviousPage": "boolean",
  "hasNextPage": "boolean"
}
```

### SessionStatisticsDto

```json
{
  "sessionId": "integer",
  "totalDistanceMeters": "double",
  "durationSeconds": "double",
  "averageSpeedKmh": "double (nullable)",
  "maxSpeedKmh": "double (nullable)",
  "gpsPointCount": "integer"
}
```

---

## 🔒 HTTP Status Codes

| Code  | Signification       | Usage                               |
| ----- | ------------------- | ----------------------------------- |
| `200` | OK                  | Requête réussie avec contenu        |
| `201` | Created             | Ressource créée avec succès         |
| `204` | No Content          | Succès sans contenu (PUT, DELETE)   |
| `400` | Bad Request         | Données invalides ou manquantes     |
| `404` | Not Found           | Ressource non trouvée               |
| `503` | Service Unavailable | Service temporairement indisponible |

---

## 🎯 Best Practices

### Pagination

- Toujours utiliser `pageNumber` et `pageSize` pour les grandes collections
- Maximum `pageSize`: 1000
- Default `pageSize`: 50

### Headers

- `Content-Type: application/json` pour les requêtes JSON
- `Content-Type: multipart/form-data` pour l'upload de fichiers

### Error Handling

- Toutes les erreurs retournent un format JSON cohérent
- Les messages d'erreur sont descriptifs et en français

### Caching

- Les queries GET sont automatiquement mises en cache (10 minutes)
- Les mutations (POST, PUT, DELETE) invalident le cache automatiquement

---

## 📝 Examples

### Example 1: Create Project with Sessions and Videos

```bash
curl -X POST http://localhost:8080/api/projects \
  -H "Content-Type: multipart/form-data" \
  -F 'ProjectData={"name":"Inspection RN7","description":"Route Nationale 7","sessions":[{"name":"Session Matin"},{"name":"Session Soir"}]}' \
  -F "SessionVideos=@/path/to/morning.mp4" \
  -F "SessionVideos=@/path/to/evening.mp4"
```

### Example 2: Get Paginated GPS Points

```bash
curl "http://localhost:8080/api/projects/1/sessions/1/gpspoints?pageNumber=1&pageSize=100"
```

### Example 3: Get Session Statistics

```bash
curl http://localhost:8080/api/projects/1/sessions/1/gpspoints/statistics
```

### Example 4: Check Health

```bash
curl http://localhost:8080/api/health/detailed
```

---

**Généré le:** 3 novembre 2025  
**API Version:** 1.0.0  
**Maintainer:** mickael62800
