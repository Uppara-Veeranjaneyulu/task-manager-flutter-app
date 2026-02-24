# Task Manager App 📝

A comprehensive Task Management application built with **Flutter** and **Firebase**. This app helps users organize their daily tasks with advanced features like cloud sync, offline support, and AI integrations.

## ✨ Features

### 🔐 Authentication & Security
*   **Secure Login/Register**: Email & Password authentication with Firebase Auth.
*   **Social Sign-In**: Google Sign-In support.
*   **Biometric Access**: Secure your app with Fingerprint/Face ID using `local_auth`.
*   **Password Management**: Forgot Password and Change Password functionality.

### 🚀 Task Management
*   **Create & Organize**: Add, edit, and delete tasks easily.
*   **Starred Tasks**: Mark important tasks as "Starred" for quick access.
*   **Categories/Lists**: Organize tasks into different lists (implied by structure).
*   **Search & Filter**: Quickly find tasks.

### 📱 Advanced Features
*   **Cloud Sync**: Real-time data synchronization with **Cloud Firestore**.
*   **Offline Support**: Local database storage using **SQLite** (`sqflite`) for offline access.
*   **Notifications**: Local push notifications to remind you of tasks.
*   **QR Scanner**: Integrated QR code scanner using `mobile_scanner`.
*   **AI Powered**: Integration with Google ML Kit.
*   **Profile Management**: Update user profile and avatar.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Firestore, Storage, App Check)
*   **State Management**: Provider
*   **Local Storage**: SQLite (sqflite)
*   **UI/UX**: Custom animations, Lottie animations, Google Fonts.

## 📦 Key Packages

*   `firebase_auth`, `cloud_firestore`: For backend services.
*   `provider`: For efficient state management.
*   `sqflite`, `path_provider`: For local data persistence.
*   `flutter_local_notifications`: For task reminders.
*   `local_auth`: For biometric authentication.
*   `mobile_scanner`: For QR code scanning capabilities.
*   `google_ml_kit`: For AI features.
*   `lottie`: For beautiful animations.

## 🏁 Getting Started

### Prerequisites
*   Flutter SDK installed (Version 3.10.4 or higher recommended).
*   A Firebase project setup with `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Uppara-Veeranjaneyulu/task-manager-flutter-app.git
    cd task_manager_app
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the app**
    ```bash
    flutter run
    ```

## 📸 Screenshots

<img width="419" height="935" alt="image" src="https://github.com/user-attachments/assets/b3828496-8b04-4775-b1ba-8c3721299ee8" /> | <img width="419" height="935" alt="image" src="https://github.com/user-attachments/assets/366dc25c-7f45-428b-bd30-9ae022a44229" />



## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📄 License


This project is open-source and available under the [MIT License](LICENSE).

=======
    
