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

$action = $_GET['action'] ?? '';
$visitor_id = $_COOKIE['visitor_id'] ?? $_POST['visitor_id'] ?? $_GET['visitor_id'] ?? '';

switch($action) {
    case 'get_user_created_room':
        getusercreatedrooms($conn, $visitor_id);
        break; 
    case 'get_user_rooms':
        getuserrooms($conn, $visitor_id); 
        break; 
    default:
        echo json_encode([
            'success' => false,
            'message' => 'unknown action'
        ]);
}

function getuserrooms($conn, $visitor_id) {
    try {
        $query = "
            SELECT r.code, r.participants, r.participant_limit, r.last_active, ur.nickname, r.status, r.logo_path
            FROM rooms r 
            LEFT JOIN user_rooms ur ON r.code = ur.room_code AND ur.user_id = ?
            WHERE r.status = 'public' OR ur.user_id = ?
            ORDER BY r.last_active DESC 
            LIMIT 20
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ss", $visitor_id, $visitor_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $rooms = [];

        while ($room = $result->fetch_assoc()) {   
            if($room['participant_limit'] == 10) { // Fixed comparison
                $par_limit = "--";
            } else {
                $par_limit = $room['participant_limit'];
            }
            
            $rooms[] = [
                'code' => $room['code'],
                'participants' => (int)$room['participants'], // Cast to int
                'participant_limit' => $room['participant_limit'],
                'last_active' => $room['last_active'],
                'nickname' => $room['nickname'] ?? 'Unknown',
                'status' => $room['status'],
                'logo_path' => $room['logo_path'] ?? '',
                'user_limits' => $par_limit
            ];
        } 
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'rooms' => $rooms,
            'count' => count($rooms)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching rooms: ' . $e->getMessage()
        ]);
    }
}

function getusercreatedrooms($conn, $visitor_id) {
    try {
        $query = "SELECT * FROM rooms WHERE creator_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $visitor_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $user_rooms = [];

        while ($room = $result->fetch_assoc()) { 
            if($room['participant_limit'] == 10) {
                $par_limit = "--";
            } else {
                $par_limit = $room['participant_limit'];
            }
            
            $user_rooms[] = [
                'code' => $room['code'],
                'participants' => (int)$room['participants'],
                'participant_limit' => $room['participant_limit'],
                'last_active' => $room['last_active'],
                'status' => $room['status'],
                'logo_path' => $room['logo_path'] ?? '',
                'user_limits' => $par_limit,
                'created_at' => $room['created_at'] ?? ''
            ];
        } 
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'user_rooms' => $user_rooms,
            'count' => count($user_rooms)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching rooms: ' . $e->getMessage()
        ]);
    }
}
?>