#  CyberChat Mobile — Cross-Platform Secure Messaging

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/PHP_API-777BB4?style=for-the-badge&logo=php&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS-success?style=for-the-badge&logo=android" />
</p>

**CyberChat Mobile** is a high-performance, real-time messaging application built with **Flutter**. It brings the power of the CyberChat ecosystem to mobile devices, featuring a sleek modern UI, asynchronous data handling, and secure API integration.

 
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


##Database structure 

```sql
-- 1. Create and select the database
CREATE DATABASE IF NOT EXISTS `cyberchat`;
USE `cyberchat`;

START TRANSACTION;

-- 2. Create Table: banned_users
CREATE TABLE `banned_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nickname` varchar(255) NOT NULL,
  `room_code` varchar(255) NOT NULL,
  `user_id` varchar(255) NOT NULL,
  `banned_by` varchar(255) NOT NULL,
  `banned_at` timestamp NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- 3. Create Table: messages
CREATE TABLE `messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_code` varchar(50) NOT NULL,
  `nickname` varchar(100) NOT NULL,
  `message` text DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `file_paths` text DEFAULT NULL,
  `visitor_hash` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Create Table: rooms
CREATE TABLE `rooms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_code` varchar(255) NOT NULL,
  `room_name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `status` enum('active','archived','deleted') DEFAULT 'active',
  `last_active` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `room_code` (`room_code`),
  KEY `status` (`status`),
  KEY `idx_rooms_status` (`status`),
  KEY `idx_rooms_active` (`last_active`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Create Table: users
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `recovery_hash` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `recovery_hash` (`recovery_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Create Table: user_rooms
CREATE TABLE `user_rooms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `room_code` varchar(255) NOT NULL,
  `last_joined` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_room` (`user_id`,`room_code`),
  KEY `room_code` (`room_code`),
  KEY `user_id` (`user_id`),
  KEY `last_joined` (`last_joined`),
  KEY `idx_user_rooms_joined` (`room_code`,`last_joined`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
```

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
