#  CyberChat Mobile — Cross-Platform Secure Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/PHP_API-777BB4?style=for-the-badge&logo=php&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS-success?style=for-the-badge&logo=android" />
</p>

**CyberChat Mobile** is a high-performance, real-time messaging application built with **Flutter**. It brings the power of the CyberChat ecosystem to mobile devices, featuring a sleek modern UI, asynchronous data handling, and secure API integration.

---

##  App Showcase

<p align="center">
  <img src="https://via.placeholder.com/200x400?text=Login+Screen" width="200" />
  <img src="https://via.placeholder.com/200x400?text=Chat+Dashboard" width="200" />
  <img src="https://via.placeholder.com/200x400?text=Message+View" width="200" />
  <img src="https://via.placeholder.com/200x400?text=User+Profile" width="200" />
</p>

---

##  Key Mobile Features

- **Reactive UI:** Built with Flutter’s declarative framework for 60FPS fluid animations.
-  **Real-Time Sync:** Asynchronous message fetching using PHP backend endpoints.
- **Secure Storage:** Sensitive user data and session tokens stored using `flutter_secure_storage`.
- **Theming:** Support for modern Light and Dark mode interfaces. 
- **Offline Caching:** Basic local persistence to view chat history without an active connection.

---

## Mobile Architecture

The app follows a **Layered Pattern** to ensure the UI remains decoupled from the business logic and API services.

```mermaid
graph TD
    A[UI Layer - Widgets] --> B[State Management]
    B --> C[Repository Layer]
    C --> D[Data Provider - HTTP/API]
    D -->|JSON| E(Remote PHP Server)
    E -->|Response| D
````

### Technical Specs:

  * **State Management:** (e.g., Provider / Riverpod / BLoC)
  * **Networking:** `http` or `dio` for RESTful API communication.
  * **Local Storage:** `shared_preferences` for settings and `Hive` for local chat history.

-----

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Frontend** | Flutter Framework (Dart) |
| **State Management** | Provider / BLoC |
| **Backend API** | PHP  |
| **Database** | MySQL (Remote) & Hive(local) |
| **Image Loading** | Cached Network Image |


-----

## Mobile Security Implementation

1.  **Token Authentication:** Secure handling of user sessions via API tokens.
2.  **HTTPS Enforcement:** All API calls are routed through secure protocols to prevent MITM attacks.
3.  **Obfuscation:** Code shrinking and obfuscation applied during release builds to protect intellectual property.
4.  **Input Validation:** Client-side form validation to ensure data integrity before server transmission.

-----

## Getting Started

1.  **Prerequisites:**
      - Flutter SDK installed.
      - Android Studio / VS Code configured.
2.  **Clone & Install:**
    ```bash
    git clone [https://github.com/abukiw86-oss/CyberChat-app.git](https://github.com/abukiw86-oss/CyberChat-app.git)
    cd CyberChat-Mobile
    flutter pub get
    ```
3.  **Configure API:**
    Update the `baseUrl` in `lib/core/constants.dart` to point to your PHP server.
4.  **Run:**
    ```bash
    flutter run --release
    ```

-----

##  Future Roadmap

  - [ ] **WebSockets:** Upgrading from polling to `web_socket_channel` for instant delivery.
  - [ ] **Biometric Lock:** Adding Fingerprint/FaceID for app access.
  - [ ] **Voice Messages:** Integrating audio recording and playback.
  - [ ] **Individual Chats:** adding   1-on-1 messaging to room dynamics.

-----
 
**Abubeker** 
```
