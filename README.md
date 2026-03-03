# Aidroid

**Aidroid** is a modern Android application built with **Flutter** and **Dart**, showcasing a clean architecture, modular design, and a rich chat interface powered by AI.

---

## Table of Contents
- [Features](#features)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Features
- **AI Chat Provider**: Seamless integration with AI services for real‑time chat.
- **Modular Architecture**: Clean separation of concerns using providers, features, and widgets.
- **Responsive UI**: Designed for various screen sizes and orientations.
- **State Management**: Utilizes `Provider` for efficient state handling.

---

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing.

### Prerequisites
- **Flutter SDK** (>= 3.0) – [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Android Studio** or another IDE with Flutter support.
- **Dart** (comes with Flutter).

---

## Installation
```bash
# Clone the repository
git clone https://github.com/SoftBridge-Labs/AiDroid.git

# Navigate to the project directory
cd aidroid

# Get Flutter packages
flutter pub get
```

---

## Running the App
```bash
# Run on an attached Android device or emulator
flutter run
```

You can also launch the app from Android Studio by selecting **Run > Run 'main.dart'**.

---

## Project Structure
```
aidroid/
├─ lib/
│  ├─ features/          # Feature‑specific UI and logic
│  │   └─ chat/          # Chat screen implementation
│  ├─ providers/         # State management and services
│  │   └─ chat_provider.dart
│  └─ main.dart          # Entry point
├─ test/                  # Unit and widget tests
├─ android/               # Android native configuration
└─ ios/                   # iOS native configuration (if applicable)
```

---

## Contributing
Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on our code of conduct, the process for submitting pull requests, and guidelines for reporting issues.

---

## License
This project is licensed under the **MIT License** – see the [LICENSE](LICENSE.md) file for details.
