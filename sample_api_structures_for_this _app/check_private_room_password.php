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
$room = $_POST['room'] ?? $_GET['room'] ?? $input['room'] ?? '';
$password = $_POST['pass'] ?? $_GET['pass'] ?? $input['pass'] ?? '';


$visitor_id = $_COOKIE['visitor_id'] ?? $_POST['visitor_id'] ?? $_GET['visitor_id'] ?? $input['visitor_id'] ?? '';

if (empty($room)) {
    $response['message'] = 'Room is required';
    echo json_encode($response);
    exit;
}

if (empty($password)) {
    $response['message'] = 'Password is required';
    echo json_encode($response);
    exit;
}

if (empty($visitor_id)) {
    $response['message'] = 'Authentication required';
    echo json_encode($response);
    exit;
}

$room = preg_replace('/[^a-zA-Z0-9_-]/', '', $room);

try {
    $stmt = $conn->prepare("SELECT room_pass, status FROM rooms WHERE code = ?");
    $stmt->bind_param("s", $room);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $response['message'] = 'Room not found';
        echo json_encode($response);
        $stmt->close();
        exit;
    }
    
    $row = $result->fetch_assoc();
    $stmt->close();
    
    if ($row['status'] !== 'private') {
        $response['message'] = 'Room is not private';
        echo json_encode($response);
        exit;
    }
    
    if ($password === $row['room_pass']) {
        $name = $_COOKIE['nickname'] ?? $_POST['name'] ?? $_GET['name'] ?? $input['name'] ?? 'User';
        $name = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
        $date = date('Y-m-d H:i:s');
        
        $insertStmt = $conn->prepare("
            INSERT INTO user_rooms (user_id, room_code, nickname, last_joined) 
            VALUES (?, ?, ?, ?) 
            ON DUPLICATE KEY UPDATE last_joined = ?, nickname = VALUES(nickname)
        ");
        $insertStmt->bind_param("sssss", $visitor_id, $room, $name, $date, $date);
        
        if ($insertStmt->execute()) {
            $roomStmt = $conn->prepare("SELECT * FROM rooms WHERE code = ?");
            $roomStmt->bind_param("s", $room);
            $roomStmt->execute();
            $roomResult = $roomStmt->get_result();
            $roomData = $roomResult->fetch_assoc();
            $roomStmt->close();
            
            $countStmt = $conn->prepare("
                UPDATE rooms SET participants = (
                    SELECT COUNT(DISTINCT user_id) FROM user_rooms WHERE room_code = ?
                ) WHERE code = ?
            ");
            $countStmt->bind_param("ss", $room, $room);
            $countStmt->execute();
            $countStmt->close();
            
            $response['success'] = true;
            $response['message'] = 'Password correct';
            $response['room'] = [
                'code' => $roomData['code'],
                'status' => $roomData['status'],
                'participants' => (int)$roomData['participants'],
                'logo_path' => $roomData['logo_path'] ?? '',
                'nickname' => $roomData['nickname'] ?? ''
            ];
        } else {
            $response['message'] = 'Failed to add user to room';
        }
        $insertStmt->close();
    } else {
        $response['message'] = 'Incorrect password';
    }
    
} catch (Exception $e) {
    error_log("Password check error: " . $e->getMessage());
    $response['message'] = 'Server error occurred';
}

echo json_encode($response);
?>