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