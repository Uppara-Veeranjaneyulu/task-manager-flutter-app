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
<p align="center">
  <img src="https://github.com/user-attachments/assets/09da5d89-ae88-4bb8-96d4-9aa6ec67a435" width="170"/>
  <img src="https://github.com/user-attachments/assets/e709d0c5-6443-4767-9c2a-57d71a706655" width="170"/>
  <img src="https://github.com/user-attachments/assets/085d5d4e-3329-4ae6-98d6-2a8c47cb70b7" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/91c50a76-ab6e-43bc-a37a-ee2afc116dc9" width="170"/>
  <img src="https://github.com/user-attachments/assets/66b1e3cc-3f16-4ae0-874a-c07384e0bd87" width="170"/>
  <img src="https://github.com/user-attachments/assets/9ea54b83-99fa-4b2e-af5b-3ef4a83bfbbb" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/0d09390d-8d26-4282-acd7-53aa459755ce" width="170"/>
  <img src="https://github.com/user-attachments/assets/d0eb964e-3dc9-4f98-8640-47480d9c3cb5" width="170"/>
  <img src="https://github.com/user-attachments/assets/0caa1f9c-062c-4451-a856-763a1f84d8e9" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/0722ba8c-d5ec-479b-ac23-2543c6d3eb92" width="170"/>
  <img src="https://github.com/user-attachments/assets/a39df3c0-74db-43d0-9a12-a46c8d9b797c" width="170"/>
  <img src="https://github.com/user-attachments/assets/97ea0c7a-5d37-464b-b0ee-3b3774280625" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/31b6d56d-3cec-429b-851d-7a1f3a4f2eaa" width="170"/>
  <img src="https://github.com/user-attachments/assets/15423cf3-4b40-4839-b645-cec606a384c9" width="170"/>
  <img src="https://github.com/user-attachments/assets/6bcf09a1-513b-49af-846a-3bd567ad691a" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/7b99a86f-c0f6-4dff-a75c-166ef6b07a06" width="170"/>
  <img src="https://github.com/user-attachments/assets/df8d8152-2767-4787-868f-691fedd89e33" width="170"/>
  <img src="https://github.com/user-attachments/assets/609ee798-5dc1-47ee-904f-57298d655dcb" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/b803101e-83d5-46f2-8d1b-a86d799833aa" width="170"/>
  <img src="https://github.com/user-attachments/assets/6191a7d1-97af-4e6e-933a-6fee5e7a027a" width="170"/>
  <img src="https://github.com/user-attachments/assets/355fa81a-e078-48f4-afc7-d1ed653a720c" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/b5f7454c-23a3-45ab-b3c3-349ef3f483f5" width="170"/>
  <img src="https://github.com/user-attachments/assets/3998dc79-903f-4317-bd75-7ea3b3083efc" width="170"/>
  <img src="https://github.com/user-attachments/assets/af4a9503-9fb4-4486-af09-7019bd3ec46a" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/41745763-869e-48b0-868d-b1b34cfac385" width="170"/>
  <img src="https://github.com/user-attachments/assets/9f7dccf2-5bd0-43bc-8c34-7f50ee4abc27" width="170"/>
  <img src="https://github.com/user-attachments/assets/afd9b809-0c20-4c7f-b776-5bc1e087deac" width="170"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/4b975384-5e2b-4598-a2ed-34798b8e73ac" width="170"/>
  <img src="https://github.com/user-attachments/assets/8829e5c6-b529-4edc-a627-a0296d8d9ea5" width="170"/>
</p>



## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📄 License


This project is open-source and available under the [MIT License](LICENSE).

=======
    
