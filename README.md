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
 <img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/03b4502d-9d05-48b4-bdaa-324426c1a03d" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/7b847044-917e-4d20-91c5-361d88efe6e0" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/4fc7260e-3e43-4f68-97ea-b3bc3ac24248" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/e2326483-9914-43c5-9295-4d51b7e0d793" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/26f05cd1-c943-43df-9acc-07ec57912bcd" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/a4268dee-b538-4862-adab-559b16bb8532" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/58aca30e-f359-4c58-b9f2-d6b5a968a841" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/b9bcb172-074a-42d2-a079-48d3620b9d9f" />
<img width="240" height="400" alt="image" src="https://github.com/user-attachments/assets/cf64f9da-bc10-4464-be3e-7d118c223d0e" />

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
