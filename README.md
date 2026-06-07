# To-Do App

A Flutter-based To-Do application with user authentication and SQLite storage.

## Features

- **Login / Sign Up** — Secure user accounts with SHA-256 hashed passwords
- **Tasks** — Add to-do items and mark them done or undone
- **Events** — Log your upcoming meetings and schedule
- **Notes** — Write and store important notes
- **Edit & Delete** — Update any item or permanently remove it from SQLite
- **Per-user data** — Each account only sees its own items
- **Logout** — Safely log out from the app

## Screens

| Screen | Description |
|--------|-------------|
| Login | Enter username and password to access the app |
| Sign Up | Create a new account |
| Home | Tabbed view showing All / Task / Event / Note |
| Add/Edit | Create a new item or edit an existing one |

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── db/
│   └── database_helper.dart   # SQLite operations (users + tasks)
└── screens/
    ├── login_screen.dart      # Login UI
    ├── signup_screen.dart     # Sign Up UI
    ├── home_screen.dart       # Main tabbed list
    └── add_task_screen.dart   # Add / Edit item
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0.0+
- Android Studio or VS Code

### Run the App

```bash
cd todo_app
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Dependencies

- `sqflite` — SQLite database for Flutter
- `path` — File path utilities
- `crypto` — SHA-256 password hashing

