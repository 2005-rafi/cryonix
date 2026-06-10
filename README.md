# Cryonix - Offline-First Smart Attendance Tracker

Cryonix is a robust, offline-first smart attendance tracking application built with Flutter. It is designed to handle unreliable network connections gracefully, allowing educators to manage classrooms, students, and attendance records locally, with seamless background synchronization to Firebase when online.

## 🌟 Key Features

* **Offline-First Architecture**: Built around a local SQLite database using **Drift**. All reads and writes happen locally first for an instant, responsive user interface regardless of network status.
* **Intelligent Background Sync**: A custom sync queue mechanism that batches and tracks local mutations. It reliably synchronizes data with Firebase Firestore in the background when connectivity is restored.
* **Rich Analytics & Dashboards**: Interactive charts built with **FL Chart**, providing insights into weekly/monthly attendance rates and overall class performance.
* **CSV Data Import**: Quickly set up classrooms by parsing and importing student lists directly from `.csv` files.
* **Modern Reactive UI**: Powered by **Riverpod** for robust state management, ensuring a clean separation of business logic and a highly responsive, fluid user experience.
* **Firebase Authentication**: Secure user authentication seamlessly integrated into the offline-first flow.

## 🏗️ Architecture & Technology Stack

The project follows a feature-driven architecture, separating concerns into discrete, testable modules.

### Core Technologies
* **Framework**: Flutter & Dart
* **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite)
* **Backend & Sync**: Firebase (Firestore & Auth)
* **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
* **Routing**: GoRouter
* **Charting**: FL Chart (`fl_chart`)

### The Offline-First Strategy
Cryonix implements a sophisticated data flow to guarantee data integrity:
1. **Local Writes**: User actions (creating a session, marking attendance) are written immediately to the local Drift database.
2. **Sync Queue**: Each modifying action also creates a `SyncQueueEntry` locally.
3. **Connectivity Observer**: A `ConnectivityService` monitors the network state.
4. **Background Processor**: When online, the `SyncService` processes the queue, pushing changes to Firebase in batches and resolving any conflicts.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`^3.11.3`)
- A configured Firebase project (ensure `firebase_options.dart` is correctly set up for your environments)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/2005-rafi/cryonix.git
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the code generation (for Drift and Freezed/Riverpod if applicable):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📦 Building for Release

To generate an optimized APK for Android:
```bash
flutter build apk --release
```
The resulting APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check [issues page](https://github.com/2005-rafi/cryonix/issues).

## 📄 License
This project is licensed under the MIT License.

## Developer
**Mohammed Rafi H**
[LinkedIn](https://www.linkedin.com/in/2005-mohammed-rafi-h/)