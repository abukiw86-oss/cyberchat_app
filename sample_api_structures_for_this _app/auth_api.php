<?php 
require 'db.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
 
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$response = ['success' => false, 'message' => ''];
 
$input = json_decode(file_get_contents('php://input'), true);
$action = $_GET['action'] ?? $input['action'] ?? '';

switch ($action) {
    case 'auth':
        handleAuth($conn, $input);
        break; 

    case 'logout':
        handleLogout();
        break;
        
    case 'get_rooms':
        getRooms($conn);
        break;
        
    case 'get_user_rooms':
        getUserRooms($conn);
        break;
    case 'update_profile':
        updateUserProfile($conn, $input);
        break;

    case 'upload_profile_image':
        uploadProfileImage($conn);
        break;

    case 'get_user_profile':
        getUserProfile($conn);
        break; 
    default:
        $response['message'] = 'Invalid action';
        echo json_encode($response);
}

function handleAuth($conn, $data) {
    global $response;
    
    $mode = $data['mode'] ?? '';
    $recovery = $data['recovery'] ?? '';
    $name = $data['name'] ?? '';

    if (!preg_match('/^[a-zA-Z0-9_-]+$/', $recovery)) {
        $response['message'] = 'Invalid phrase! Only letters, numbers, hyphens, and underscores allowed.';
        echo json_encode($response);
        return;
    }
    
    if (empty($name)) {
        $response['message'] = 'Name is required';
        echo json_encode($response);
        return;
    }
    
    $recovery_hashed = hash('sha256', $recovery);
    
    if ($mode === 'create') { 
        $stmt = $conn->prepare("SELECT id, name, recovery_phrase, recovery_hash, user_logo, created_at FROM users WHERE recovery_hash = ? AND name = ?");
        $stmt->bind_param("ss", $recovery_hashed, $name);
        $stmt->execute();
        $check = $stmt->get_result();
        
        if ($check->num_rows > 0) {
            $response['message'] = 'User  Creation Failed!';
        } else {
            $stmt = $conn->prepare("INSERT INTO users (name, recovery_phrase, recovery_hash, created_at) VALUES (?, ?, ?, NOW())");
            $stmt->bind_param("sss", $name, $recovery, $recovery_hashed);

            if ($stmt->execute()) {
                $newUserId = $stmt->insert_id;

                $fetchStmt = $conn->prepare("SELECT id, name, recovery_phrase, recovery_hash, user_logo,bio, created_at FROM users WHERE id = ?");
                $fetchStmt->bind_param("i", $newUserId);
                $fetchStmt->execute();
                $newUserData = $fetchStmt->get_result()->fetch_assoc();
                $fetchStmt->close();
                  
                $response['success'] = true;
                $response['message'] = 'Account created successfully!';
                $response['user'] = [
                    'id' => $newUserData['id'],
                    'name' => $newUserData['name'],
                    'recovery_phrase' => $newUserData['recovery_phrase'],
                    'recovery_hash' => $newUserData['recovery_hash'],
                    'user_logo' => $newUserData['user_logo'],
                    'bio'=> $newUserData['bio'],
                    'created_at' => $newUserData['created_at'],
                    'is_new' => true
                ];
            } else {
                $response['message'] = 'Failed to create account: ' . $conn->error;
            }
        }
    } 
    elseif ($mode === 'login') {
        $stmt = $conn->prepare("SELECT id, name, recovery_phrase, recovery_hash, user_logo,bio, created_at FROM users WHERE recovery_hash = ? AND name = ?");
        $stmt->bind_param("ss", $recovery_hashed, $name);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $userData = $result->fetch_assoc();
             
            
            $response['success'] = true;
            $response['message'] = 'Login successful!';
            $response['user'] = [
                'id' => $userData['id'],
                'name' => $userData['name'],
                'recovery_phrase' => $userData['recovery_phrase'],
                'recovery_hash' => $userData['recovery_hash'],
                'user_logo' => $userData['user_logo'],
                'created_at' => $userData['created_at'],
                'is_new' => false
            ];
        }
        else{
            $response['message'] = 'Unknown User';
        }
    } 
    else {
        $response['message'] = 'Invalid mode';
    }
    
    echo json_encode($response);
}
function handleLogout() {
    setcookie('visitor_id', '', time() - 3600, "/");
    setcookie('nickname', '', time() - 3600, "/");
    
    $response['success'] = true;
    $response['message'] = 'Logged out successfully';
    echo json_encode($response);
}

function getRooms($conn) {
    global $response;
    
    $result = $conn->query("SELECT * FROM rooms ORDER BY last_active DESC");
    $rooms = [];
    
    while ($row = $result->fetch_assoc()) {
        $rooms[] = [
            'code' => $row['code'],
            'participants' => $row['participants'],
            'last_active' => $row['last_active'],
            'nickname' => $row['nickname'],
            'status' => $row['status'],
            'logo_path' => $row['logo_path'],
            'user_limits' => $row['user_limits']
        ];
    }
    
    $response['success'] = true;
    $response['rooms'] = $rooms;
    $response['count'] = count($rooms);
    echo json_encode($response);
}
function updateUserProfile($conn, $data) {
    $response = ['success' => false, 'message' => ''];
     
    $visitor_id = $_COOKIE['visitor_id'] ?? $data['visitor_id'] ?? '';
    $name = $data['name'] ?? '';
    $bio = $data['bio'] ?? '';
    $recovery_phrase = $data['recovery_phrase'] ?? '';
    $user_logo = $data['user_logo'] ?? '';
    
    if (empty($visitor_id)) {
        $response['message'] = 'Not authenticated';
        echo json_encode($response);
        return;
    }
    
    if (empty($name)) {
        $response['message'] = 'Name is required';
        echo json_encode($response);
        return;
    }
     
    $name = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
    $bio = htmlspecialchars($bio, ENT_QUOTES, 'UTF-8');
    $recovery_phrase = htmlspecialchars($recovery_phrase, ENT_QUOTES, 'UTF-8');
     
    $updates = [];
    $params = [];
    $types = '';
     
    $updates[] = "name = ?";
    $params[] = $name;
    $types .= 's';
    
    $updates[] = "bio = ?";
    $params[] = $bio;
    $types .= 's';
     
    if (!empty($recovery_phrase)) { 
        if (!preg_match('/^[a-zA-Z0-9_-]+$/', $recovery_phrase)) {
            $response['message'] = 'Invalid recovery phrase format';
            echo json_encode($response);
            return;
        }
         
        $recovery_hashed = hash('sha256', $recovery_phrase);
        
        $updates[] = "recovery_phrase = ?";
        $params[] = $recovery_phrase;
        $types .= 's';
        
        $updates[] = "recovery_hash = ?";
        $params[] = $recovery_hashed;
        $types .= 's';
    }
     
    if (!empty($user_logo)) {
        $updates[] = "user_logo = ?";
        $params[] = $user_logo;
        $types .= 's';
    } 
    $params[] = $visitor_id;
    $types .= 's';
     
    $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE recovery_hash = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        $response['message'] = 'Database error: ' . $conn->error;
        echo json_encode($response);
        return;
    } 
    $stmt->bind_param($types, ...$params);
    
    if ($stmt->execute()) { 
        $fetchStmt = $conn->prepare("SELECT id, name, recovery_phrase, recovery_hash, user_logo, bio, created_at FROM users WHERE recovery_hash = ?");
        $fetchStmt->bind_param("s", $visitor_id);
        $fetchStmt->execute();
        $result = $fetchStmt->get_result();
        $userData = $result->fetch_assoc();
        $fetchStmt->close();
        
        $response['success'] = true;
        $response['message'] = 'Profile updated successfully';
        $response['user'] = [
            'id' => $userData['id'],
            'name' => $userData['name'],
            'recovery_phrase' => $userData['recovery_phrase'],
            'recovery_hash' => $userData['recovery_hash'],
            'user_logo' => $userData['user_logo'],
            'bio' => $userData['bio'],
            'created_at' => $userData['created_at']
        ];
    } else {
        $response['message'] = 'Failed to update profile: ' . $stmt->error;
    }
    
    $stmt->close();
    echo json_encode($response);
}
function uploadProfileImage($conn) {
    $response = ['success' => false, 'message' => ''];
     
    $visitor_id = $_COOKIE['visitor_id'] ?? $_POST['visitor_id'] ?? '';
    
    if (empty($visitor_id)) {
        $response['message'] = 'Not authenticated';
        echo json_encode($response);
        return;
    } 
    if (!isset($_FILES['profile_image']) || $_FILES['profile_image']['error'] !== UPLOAD_ERR_OK) {
        $response['message'] = 'No image uploaded or upload error';
        echo json_encode($response);
        return;
    }
    
    $file = $_FILES['profile_image'];
     
    $allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime_type = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!in_array($mime_type, $allowed_types)) {
        $response['message'] = 'Invalid file type. Only JPG, PNG, GIF, and WEBP are allowed.';
        echo json_encode($response);
        return;
    }
     
    if ($file['size'] > 5 * 1024 * 1024) {
        $response['message'] = 'File too large. Maximum size is 5MB.';
        echo json_encode($response);
        return;
    } 
    $upload_dir = 'uploads/profile_images/';
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    } 
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = 'profile_' . $visitor_id . '_' . time() . '.' . $extension;
    $filepath = $upload_dir . $filename;
     
    if (move_uploaded_file($file['tmp_name'], $filepath)) { 
        $stmt = $conn->prepare("UPDATE users SET user_logo = ? WHERE recovery_hash = ?");
        $stmt->bind_param("ss", $filepath, $visitor_id);
        
        if ($stmt->execute()) {
            $response['success'] = true;
            $response['message'] = 'Profile image uploaded successfully';
            $response['image_url'] = $filepath;
        } else {
            $response['message'] = 'Database update failed'; 
            unlink($filepath);
        }
        $stmt->close();
    } else {
        $response['message'] = 'Failed to save uploaded file';
    }
    
    echo json_encode($response);
}
function getUserProfile($conn) {
    $response = ['success' => false, 'message' => ''];
     
    $visitor_id = $_COOKIE['visitor_id'] ?? $_GET['visitor_id'] ?? $_POST['visitor_id'] ?? '';
    
    if (empty($visitor_id)) {
        $response['message'] = 'Not authenticated';
        echo json_encode($response);
        return;
    }
    
    $stmt = $conn->prepare("SELECT id, name, recovery_phrase, recovery_hash, user_logo, bio, created_at FROM users WHERE recovery_hash = ?");
    $stmt->bind_param("s", $visitor_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) { 
        $roomsStmt = $conn->prepare("SELECT COUNT(*) as room_count FROM rooms WHERE creator_id = ?");
        $roomsStmt->bind_param("s", $visitor_id);
        $roomsStmt->execute();
        $roomsResult = $roomsStmt->get_result();
        $roomsCount = $roomsResult->fetch_assoc()['room_count'];
        $roomsStmt->close(); 

        $messagesStmt = $conn->prepare("SELECT COUNT(*) as message_count FROM messages WHERE visitor_hash = ?");
        $messagesStmt->bind_param("s", $visitor_id);
        $messagesStmt->execute();
        $messagesResult = $messagesStmt->get_result();
        $messagesCount = $messagesResult->fetch_assoc()['message_count'];
        $messagesStmt->close();
        
        $response['success'] = true;
        $response['user'] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'recovery_phrase' => $row['recovery_phrase'],
            'recovery_hash' => $row['recovery_hash'],
            'user_logo' => $row['user_logo'],
            'bio' => $row['bio'],
            'created_at' => $row['created_at'],
            'stats' => [
                'rooms_created' => $roomsCount,
                'messages_sent' => $messagesCount
            ]
        ];
    } else {
        $response['message'] = 'User not found';
    }
    
    $stmt->close();
    echo json_encode($response);
}

function getUserRooms($conn) {
    global $response;
    
    $hash = $_COOKIE['visitor_id'] ?? '';
    
    if (empty($hash)) {
        $response['message'] = 'Not authenticated';
        echo json_encode($response);
        return;
    }
    
    $stmt = $conn->prepare("SELECT * FROM rooms WHERE created_by = ? ORDER BY last_active DESC");
    $stmt->bind_param("s", $hash);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $rooms = [];
    while ($row = $result->fetch_assoc()) {
        $rooms[] = [
            'code' => $row['code'],
            'participants' => $row['participants'],
            'last_active' => $row['last_active'],
            'nickname' => $row['nickname'],
            'status' => $row['status'],
            'logo_path' => $row['logo_path'],
            'user_limits' => $row['user_limits']
        ];
    }
    
    $response['success'] = true;
    $response['rooms'] = $rooms;
    echo json_encode($response);
}
?>