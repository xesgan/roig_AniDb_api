# AniDB Flutter Client

Flutter application for browsing anime data from the AniDB HTTP API.

The app provides anime discovery features such as trending titles, random recommendations, detailed information and similar anime suggestions.

## Features

- Browse trending anime
- Discover random recommendations
- View detailed anime information
- Explore similar titles
- XML parsing from the AniDB API
- Local in-memory caching to avoid repeated requests
- Request throttling to respect API rate limits
- Loading and error-state handling

## Tech Stack

- Flutter
- Dart
- Provider / ChangeNotifier
- HTTP
- XML

## Structure

```text
lib/
├── models/      API and domain models
├── provider/    API communication and application state
├── screens/     Main application screens
└── widgets/     Reusable UI components
```

## API Integration

The application communicates with the AniDB HTTP API and converts XML responses into Dart models used by the UI.

The provider layer also handles caching, request throttling and application state.

## Background

This project was developed during Higher Vocational Training in Multiplatform Application Development (DAM) as practical work with Flutter, external APIs and state management.

---

**Elias Roig**
