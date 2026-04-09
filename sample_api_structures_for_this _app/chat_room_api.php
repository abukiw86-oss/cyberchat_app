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

if ($action !== 'join' && 'get_participants') {
    if (!isset($_COOKIE['visitor_id']) && !isset($input['visitor_id'])) {
        $response['message'] = 'Not authenticated';
        echo json_encode($response);
        exit;
    }
}

$visitor_id = $_COOKIE['visitor_id'] ?? $input['visitor_id'] ?? '';

switch ($action) {
    case 'join':
        joinRoom($conn, $input, $visitor_id);
        break;
        
    case 'get_messages':
        getMessages($conn, $input);
        break;
        
    case 'send_message':
        sendMessage($conn, $input, $visitor_id);
        break;
        
    case 'get_participants':
        getParticipants($conn, $input);
        break;
        
    case 'get_banned_users':
        getBannedUsers($conn, $input, $visitor_id);
        break;
        
    case 'remove_user':
        removeUser($conn, $input, $visitor_id);
        break;
        
    case 'unban_user':
        unbanUser($conn, $input, $visitor_id);
        break;
        
    case 'make_owner':
        makeOwner($conn, $input, $visitor_id);
        break;
        
    case 'leave_room':
        leaveRoom($conn, $input, $visitor_id);
        break;
        
    case 'update_room_limit':
        updateRoomLimit($conn, $input, $visitor_id);
        break;
        
    case 'upload_logo':
        uploadRoomLogo($conn, $input, $visitor_id);
        break;
        
    case 'get_room_info':
        getRoomInfo($conn, $input);
        break;
 
    default:
        $response['message'] = 'Invalid action';
        echo json_encode($response);
}

function joinRoom($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $name = htmlspecialchars($data['name'] ?? '', ENT_QUOTES, 'UTF-8');
    $password = $data['password'] ?? '';
    
    if (empty($room) || empty($name)) {
        $response['message'] = 'Room and name are required';
        echo json_encode($response);
        return;
    }
     
    $banstmt = $conn->prepare("SELECT * FROM banned_users WHERE user_id = ? AND room_code = ?");
    $banstmt->bind_param("ss", $visitor_id, $room);
    $banstmt->execute();
    $banresult = $banstmt->get_result();
    if($banresult->num_rows >= 1){
        $response['message'] = 'You are banned from this room';
        $response['banned'] = true;
        echo json_encode($response);
        return;
    }
    $banstmt->close();
     
    $stmt = $conn->prepare("SELECT * FROM rooms WHERE code = ?");
    $stmt->bind_param("s", $room);
    $stmt->execute();
    $res = $stmt->get_result();
    
    $is_creator = false;
    $room_status = 'public';
    $room_invi = '';
    $roomData = null;
    
    if ($res->num_rows === 0) { 
        $room_type = $data['room_type'] ?? 'public';
        $ins = $conn->prepare("INSERT INTO rooms (code, creator_id, status, room_pass, last_active) VALUES (?, ?, ?, '', NOW())");
        $ins->bind_param("sss", $room, $visitor_id, $room_type);
        $ins->execute();
        $ins->close();
        $is_creator = true;
        $room_status = $room_type; 

        if ($room_status === 'private' && $is_creator) {
            $link = bin2hex(random_bytes(6));
            $pa = $conn->prepare("UPDATE rooms SET room_pass = ? WHERE code = ?");
            $pa->bind_param("ss", $link, $room);
            $pa->execute();
            $pa->close();
            $room_invi = $link;
        }
    } else {
        $roomData = $res->fetch_assoc();
        $is_creator = ($roomData['creator_id'] === $visitor_id);
        $room_status = $roomData['status'];
        $room_invi = $roomData['room_pass'];
         
        if ($room_status === 'private' && !$is_creator) {
            $check_user = $conn->prepare("SELECT id FROM user_rooms WHERE user_id = ? AND room_code = ?");
            $check_user->bind_param("ss", $visitor_id, $room);
            $check_user->execute();
            $user_exists = $check_user->get_result()->num_rows > 0;
            $check_user->close();
            
            if (!$user_exists) { 
                if (empty($password) || $password !== $roomData['room_pass']) {
                    $response['message'] = 'Password required for private room';
                    $response['requires_password'] = true;
                    echo json_encode($response);
                    return;
                }
            }
        }
    }
    $stmt->close();
     
    $partstmt = $conn->prepare("SELECT * FROM user_rooms WHERE room_code = ? AND user_id = ?");
    $partstmt->bind_param("ss", $room, $visitor_id);
    $partstmt->execute();
    $user_already_joined = $partstmt->get_result()->num_rows > 0;
    $partstmt->close();
     
    if (!$user_already_joined && !$is_creator) {
        $count_stmt = $conn->prepare("SELECT COUNT(*) as current_count FROM user_rooms WHERE room_code = ?");
        $count_stmt->bind_param("s", $room);
        $count_stmt->execute();
        $count_result = $count_stmt->get_result();
        $current_count = $count_result->fetch_assoc()['current_count'];
        $count_stmt->close();
        
        if ($roomData && $roomData['enable_par_limit'] !== "no" && $roomData['participant_limit'] <= $current_count) {
            $response['message'] = 'Room limit reached';
            echo json_encode($response);
            return;
        }
    }
     
    $up = $conn->prepare("INSERT INTO user_rooms (user_id, room_code, nickname, last_joined) VALUES (?, ?, ?, NOW()) 
                         ON DUPLICATE KEY UPDATE last_joined = NOW(), nickname = VALUES(nickname)");
    $up->bind_param("sss", $visitor_id, $room, $name);
    $up->execute();
    $up->close(); 

    $cnt_sql = "UPDATE rooms SET participants = (SELECT COUNT(DISTINCT user_id) FROM user_rooms WHERE room_code = ?), last_active = NOW() WHERE code = ?";
    $cnt = $conn->prepare($cnt_sql);
    $cnt->bind_param("ss", $room, $room);
    $cnt->execute();
    $cnt->close();
     
    $roomInfo = getRoomInfoById($conn, $room);
    
    $response['success'] = true;
    $response['message'] = 'Joined room successfully';
    $response['room'] = $roomInfo;
    $response['is_creator'] = $is_creator;
    $response['invite_code'] = $room_invi;
    
    echo json_encode($response);
}

function getMessages($conn, $data) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $last_id = (int)($data['last_id'] ?? 0);
    $limit = (int)($data['limit'] ?? 50);
    
    if (empty($room)) {
        $response['message'] = 'Room is required';
        echo json_encode($response);
        return;
    }
     
    $stmt = $conn->prepare("SELECT m.*, u.user_logo FROM messages m 
                           LEFT JOIN users u ON m.visitor_hash COLLATE utf8mb4_unicode_ci = u.recovery_hash 
                           WHERE m.room_code = ? AND m.id > ? 
                           ORDER BY m.id ASC LIMIT ?");
    
    if (!$stmt) {
        $response['message'] = 'Prepare failed: ' . $conn->error;
        echo json_encode($response);
        return;
    }
    
    $stmt->bind_param("sii", $room, $last_id, $limit);
    
    if (!$stmt->execute()) {
        $response['message'] = 'Execute failed: ' . $stmt->error;
        echo json_encode($response);
        $stmt->close();
        return;
    }
    
    $result = $stmt->get_result();
    
    $messages = [];
    while ($row = $result->fetch_assoc()) {
        $filePaths = [];
        if (!empty($row['file_paths'])) {
            $decoded = json_decode($row['file_paths'], true);
            if (is_array($decoded)) {
                $filePaths = $decoded;
            }
        } elseif (!empty($row['file_path'])) {
            $filePaths = [$row['file_path']];
        }
        
        $messages[] = [
            'id' => (int)$row['id'],
            'nickname' => $row['nickname'] ?? '',
            'message' => $row['message'] ?? '',
            'file_path' => $row['file_path'] ?? '',
            'file_paths' => $filePaths,
            'created_at' => $row['created_at'] ?? '',
            'visitor_hash' => $row['visitor_hash'] ?? '',
            'user_logo' => $row['user_logo'] ?? null
        ];
    }
    $stmt->close();
    
    $response['success'] = true;
    $response['messages'] = $messages;
    $response['count'] = count($messages);
    
    echo json_encode($response);
}

function sendMessage($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $message = htmlspecialchars($data['message'] ?? '', ENT_QUOTES, 'UTF-8');
    $name = htmlspecialchars($data['name'] ?? '', ENT_QUOTES, 'UTF-8');
    
    if (empty($room) || empty($message)) {
        $response['message'] = 'Room and message are required';
        echo json_encode($response);
        return;
    }
    
    $stmt = $conn->prepare("INSERT INTO messages (room_code, nickname, visitor_hash, message) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $room, $name, $visitor_id, $message);
    
    if ($stmt->execute()) {
        $message_id = $stmt->insert_id;
         
        $update = $conn->prepare("UPDATE rooms SET last_active = NOW() WHERE code = ?");
        $update->bind_param("s", $room);
        $update->execute();
        $update->close();
        
        $response['success'] = true;
        $response['message_id'] = $message_id;
        $response['message'] = 'Message sent successfully';
    } else {
        $response['message'] = 'Failed to send message';
    }
    
    $stmt->close();
    echo json_encode($response);
}

function getParticipants($conn, $data) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    
    if (empty($room)) {
        $response['message'] = 'Room is required';
        echo json_encode($response);
        return;
    }
    
    $stmt = $conn->prepare("SELECT user_id, nickname, last_joined FROM user_rooms WHERE room_code = ? ORDER BY last_joined DESC");
    $stmt->bind_param("s", $room);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $participants = [];
    while ($row = $result->fetch_assoc()) {
        $participants[] = [
            'user_id' => $row['user_id'],
            'nickname' => $row['nickname'],
            'last_joined' => $row['last_joined']
        ];
    }
    $stmt->close();
    
    $response['success'] = true;
    $response['participants'] = $participants;
    $response['count'] = count($participants);
    
    echo json_encode($response);
}

function getBannedUsers($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    
    if (empty($room)) {
        $response['message'] = 'Room is required';
        echo json_encode($response);
        return;
    }
     
    $check = $conn->prepare("SELECT creator_id FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if (!$roomData || $roomData['creator_id'] !== $visitor_id) {
        $response['message'] = 'Only room creator can view banned users';
        echo json_encode($response);
        return;
    }
    
    $stmt = $conn->prepare("SELECT user_id, nickname, banned_by, banned_at FROM banned_users WHERE room_code = ?");
    $stmt->bind_param("s", $room);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $banned = [];
    while ($row = $result->fetch_assoc()) {
        $banned[] = $row;
    }
    $stmt->close();
    
    $response['success'] = true;
    $response['banned_users'] = $banned;
    
    echo json_encode($response);
}

function removeUser($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $user_id = $data['user_id'] ?? '';
    $user_name = $data['user_name'] ?? '';
    
    if (empty($room) || empty($user_id)) {
        $response['message'] = 'Room and user_id are required';
        echo json_encode($response);
        return;
    }
     
    $check = $conn->prepare("SELECT creator_id FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if (!$roomData || $roomData['creator_id'] !== $visitor_id) {
        $response['message'] = 'Only room creator can remove users';
        echo json_encode($response);
        return;
    }
    
    if ($user_id === $roomData['creator_id']) {
        $response['message'] = 'Cannot remove room creator';
        echo json_encode($response);
        return;
    }
    
    $conn->begin_transaction();
    
    try { 
        $remove = $conn->prepare("DELETE FROM user_rooms WHERE room_code = ? AND user_id = ?");
        $remove->bind_param("ss", $room, $user_id);
        $remove->execute();
        $remove->close();
         
        $ban = $conn->prepare("INSERT INTO banned_users (room_code, user_id, nickname, banned_by, banned_at) VALUES (?, ?, ?, ?, NOW())");
        $ban->bind_param("ssss", $room, $user_id, $user_name, $visitor_id);
        $ban->execute();
        $ban->close();
        
        $conn->commit();
         
        $cnt_sql = "UPDATE rooms SET participants = (SELECT COUNT(DISTINCT user_id) FROM user_rooms WHERE room_code = ?) WHERE code = ?";
        $cnt = $conn->prepare($cnt_sql);
        $cnt->bind_param("ss", $room, $room);
        $cnt->execute();
        $cnt->close();
        
        $response['success'] = true;
        $response['message'] = 'User removed and banned successfully';
    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Failed to remove user: ' . $e->getMessage();
    }
    
    echo json_encode($response);
}

function unbanUser($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $user_id = $data['user_id'] ?? '';
    
    if (empty($room) || empty($user_id)) {
        $response['message'] = 'Room and user_id are required';
        echo json_encode($response);
        return;
    }
     
    $check = $conn->prepare("SELECT creator_id FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if (!$roomData || $roomData['creator_id'] !== $visitor_id) {
        $response['message'] = 'Only room creator can unban users';
        echo json_encode($response);
        return;
    }
    
    $unban = $conn->prepare("DELETE FROM banned_users WHERE room_code = ? AND user_id = ?");
    $unban->bind_param("ss", $room, $user_id);
    
    if ($unban->execute()) {
        $response['success'] = true;
        $response['message'] = 'User unbanned successfully';
    } else {
        $response['message'] = 'Failed to unban user';
    }
    
    $unban->close();
    echo json_encode($response);
}

function makeOwner($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $new_owner_id = $data['new_owner_id'] ?? '';
    $new_owner_name = $data['new_owner_name'] ?? '';
    
    if (empty($room) || empty($new_owner_id)) {
        $response['message'] = 'Room and new_owner_id are required';
        echo json_encode($response);
        return;
    }
     
    $check = $conn->prepare("SELECT creator_id FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if (!$roomData || $roomData['creator_id'] !== $visitor_id) {
        $response['message'] = 'Only room creator can transfer ownership';
        echo json_encode($response);
        return;
    }
    
    $conn->begin_transaction();
    
    try { 
        $update = $conn->prepare("UPDATE rooms SET creator_id = ? WHERE code = ?");
        $update->bind_param("ss", $new_owner_id, $room);
        $update->execute();
        $update->close();
         
        $check_participant = $conn->prepare("SELECT COUNT(*) FROM user_rooms WHERE room_code = ? AND user_id = ?");
        $check_participant->bind_param("ss", $room, $new_owner_id);
        $check_participant->execute();
        $check_participant->bind_result($count);
        $check_participant->fetch();
        $check_participant->close();
        
        if ($count == 0) {
            $add = $conn->prepare("INSERT INTO user_rooms (room_code, user_id, nickname, last_joined) VALUES (?, ?, ?, NOW())");
            $add->bind_param("sss", $room, $new_owner_id, $new_owner_name);
            $add->execute();
            $add->close();
        }
        
        $conn->commit();
        
        $response['success'] = true;
        $response['message'] = 'Room ownership transferred successfully';
    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Failed to transfer ownership: ' . $e->getMessage();
    }
    
    echo json_encode($response);
}

function leaveRoom($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    
    if (empty($room)) {
        $response['message'] = 'Room is required';
        echo json_encode($response);
        return;
    }
     
    $check = $conn->prepare("SELECT creator_id FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if ($roomData && $roomData['creator_id'] === $visitor_id) {
        $response['message'] = 'Room creator cannot leave. Delete the room instead.';
        echo json_encode($response);
        return;
    }
    
    $remove = $conn->prepare("DELETE FROM user_rooms WHERE room_code = ? AND user_id = ?");
    $remove->bind_param("ss", $room, $visitor_id);
    
    if ($remove->execute()) { 
        $cnt_sql = "UPDATE rooms SET participants = (SELECT COUNT(DISTINCT user_id) FROM user_rooms WHERE room_code = ?) WHERE code = ?";
        $cnt = $conn->prepare($cnt_sql);
        $cnt->bind_param("ss", $room, $room);
        $cnt->execute();
        $cnt->close();
        
        $response['success'] = true;
        $response['message'] = 'Left room successfully';
    } else {
        $response['message'] = 'Failed to leave room';
    }
    
    $remove->close();
    echo json_encode($response);
}

function updateRoomLimit($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $limit = intval($data['limit'] ?? 0);
    
    if (empty($room) || $limit <= 0) {
        $response['message'] = 'Room and valid limit are required';
        echo json_encode($response);
        return;
    }
     
    $check = $conn->prepare("SELECT creator_id, participants FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if (!$roomData || $roomData['creator_id'] !== $visitor_id) {
        $response['message'] = 'Only room creator can change limits';
        echo json_encode($response);
        return;
    }
    
    if ($limit < $roomData['participants']) {
        $response['message'] = 'Limit cannot be less than current participants';
        echo json_encode($response);
        return;
    }
    
    $update = $conn->prepare("UPDATE rooms SET participant_limit = ?, enable_par_limit = 'yes' WHERE code = ?");
    $update->bind_param("is", $limit, $room);
    
    if ($update->execute()) {
        $response['success'] = true;
        $response['message'] = 'Room limit updated successfully';
    } else {
        $response['message'] = 'Failed to update room limit';
    }
    
    $update->close();
    echo json_encode($response);
}

function uploadRoomLogo($conn, $data, $visitor_id) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    $logo_data = $data['logo_data'] ?? '';  
    
    if (empty($room) || empty($logo_data)) {
        $response['message'] = 'Room and logo data are required';
        echo json_encode($response);
        return;
    } 

    $check = $conn->prepare("SELECT creator_id FROM rooms WHERE code = ?");
    $check->bind_param("s", $room);
    $check->execute();
    $roomData = $check->get_result()->fetch_assoc();
    $check->close();
    
    if (!$roomData || $roomData['creator_id'] !== $visitor_id) {
        $response['message'] = 'Only room creator can change logo';
        echo json_encode($response);
        return;
    }
     
    $image_parts = explode(";base64,", $logo_data);
    if (count($image_parts) < 2) {
        $response['message'] = 'Invalid image data';
        echo json_encode($response);
        return;
    }
    
    $image_base64 = base64_decode($image_parts[1]);
    $file_name = 'room_logos/room_' . $room . '_' . time() . '.png';
     
    if (!file_exists('room_logos')) {
        mkdir('room_logos', 0777, true);
    }
    
    if (file_put_contents($file_name, $image_base64)) {
        $update = $conn->prepare("UPDATE rooms SET logo_path = ? WHERE code = ?");
        $update->bind_param("ss", $file_name, $room);
        $update->execute();
        $update->close();
        
        $response['success'] = true;
        $response['logo_path'] = $file_name;
        $response['message'] = 'Logo uploaded successfully';
    } else {
        $response['message'] = 'Failed to save logo';
    }
    
    echo json_encode($response);
}

function getRoomInfo($conn, $data) {
    global $response;
    
    $room = preg_replace('/[^a-zA-Z0-9_-]/', '', $data['room'] ?? '');
    
    if (empty($room)) {
        $response['message'] = 'Room is required';
        echo json_encode($response);
        return;
    }
    
    $roomInfo = getRoomInfoById($conn, $room);
    
    if ($roomInfo) {
        $response['success'] = true;
        $response['room'] = $roomInfo;
    } else {
        $response['message'] = 'Room not found';
    }
    
    echo json_encode($response);
}
 

function getRoomInfoById($conn, $room) {
    $stmt = $conn->prepare("SELECT * FROM rooms WHERE code = ?");
    $stmt->bind_param("s", $room);
    $stmt->execute();
    $result = $stmt->get_result();
    $roomInfo = $result->fetch_assoc();
    $stmt->close();
    
    return $roomInfo;
}
?>