<?php 
require 'db.php';
 
header('Content-Type: application/json');

if (!isset($_COOKIE['visitor_id'])) {
    ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Not authenticated']);
    exit;
}

$room = $_POST['room'] ?? '';
$name = $_POST['name'] ?? '';
$user = $_COOKIE['visitor_id'];
 
if (empty($room) || empty($name)) {
    ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Room and name are required']);
    exit;
}
 
$allowed = [ 
    'jpg','jpeg','png','gif','bmp','webp','svg','ico', 
    'mp4','avi','mov','wmv','flv','webm','mkv', 
    'mp3','wav','ogg','m4a','aac','flac', 
    'pdf','doc','docx','xls','xlsx','ppt','pptx','txt','rtf', 
    'zip','rar','7z','tar','gz', 
    'csv','sql','json','xml','js','css','html','php','py','java','cpp','c','cs', 
    'exe','msi','apk','deb','rpm', 
    'psd','ai','eps','tiff'
];

$maxFileSize = 10 * 1024 * 1024;  
$maxTotalSize = 50 * 1024 * 1024;  
$uploadDir = "uploads/";
 
if (!is_dir($uploadDir)) {
    if (!mkdir($uploadDir, 0755, true)) {
        ob_end_clean();
        echo json_encode(['status' => 'error', 'message' => 'Could not create upload directory']);
        exit;
    }
}
 
if (empty($_FILES['files']['name'][0])) {
    ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'No files selected']);
    exit;
}

$files = $_FILES['files'];
$uploadResults = [];
$successCount = 0;
$errorCount = 0;
$uploadedFiles = [];
$filePaths = [];
 
foreach ($files['name'] as $index => $fileName) {
    $file = [
        'name' => $files['name'][$index],
        'type' => $files['type'][$index],
        'tmp_name' => $files['tmp_name'][$index],
        'error' => $files['error'][$index],
        'size' => $files['size'][$index]
    ];
 
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $uploadResults[] = [
            'file' => $fileName, 
            'status' => 'error', 
            'message' => getUploadError($file['error'])
        ];
        $errorCount++;
        continue;
    }
    
    if ($file['size'] > $maxFileSize) {
        $uploadResults[] = [
            'file' => $fileName, 
            'status' => 'error', 
            'message' => 'File too large (max 10MB)'
        ];
        $errorCount++;
        continue;
    }
    
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    
    if (!in_array($ext, $allowed)) {
        $uploadResults[] = [
            'file' => $fileName, 
            'status' => 'error', 
            'message' => 'File type not allowed'
        ];
        $errorCount++;
        continue;
    }
 
    $safeName = time() . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
    $targetPath = $uploadDir . $safeName;

    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        $uploadedFiles[] = [
            'original_name' => $fileName,
            'safe_name' => $safeName,
            'path' => $targetPath,
            'type' => $file['type']
        ];
        $filePaths[] = $targetPath;
        $successCount++;
    } else {
        $uploadResults[] = [
            'file' => $fileName, 
            'status' => 'error', 
            'message' => 'Failed to move uploaded file'
        ];
        $errorCount++;
    }
}
 
if (count($uploadedFiles) > 0) { 
    $fileNames = array_map(function($file) {
        return htmlspecialchars(basename($file['original_name']), ENT_QUOTES, 'UTF-8');
    }, $uploadedFiles);
    
    $message = "📎 " . count($uploadedFiles) . " file(s): " . implode(', ', $fileNames);
     
    $filePathsJson = json_encode($filePaths);
    
    $stmt = $conn->prepare("INSERT INTO messages (room_code, nickname, visitor_hash, file_path, message, file_paths) VALUES (?, ?, ?, ?, ?, ?)");
    
    if ($stmt) { 
        $mainFilePath = $uploadedFiles[0]['path'];
        
        $stmt->bind_param("ssssss", $room, $name, $user, $mainFilePath, $message, $filePathsJson);
        if ($stmt->execute()) { 
            foreach ($uploadedFiles as $file) {
                $uploadResults[] = [
                    'file' => $file['original_name'], 
                    'status' => 'success', 
                    'message' => 'Uploaded successfully'
                ];
            }
        } else { 
            foreach ($filePaths as $path) {
                if (file_exists($path)) {
                    unlink($path);
                }
            }
            $errorCount += count($uploadedFiles);
            $successCount = 0;
            foreach ($uploadedFiles as $file) {
                $uploadResults[] = [
                    'file' => $file['original_name'], 
                    'status' => 'error', 
                    'message' => 'Database insert failed'
                ];
            }
        }
        $stmt->close();
    } else { 
        foreach ($filePaths as $path) {
            if (file_exists($path)) {
                unlink($path);
            }
        }
        $errorCount += count($uploadedFiles);
        $successCount = 0;
        foreach ($uploadedFiles as $file) {
            $uploadResults[] = [
                'file' => $file['original_name'], 
                'status' => 'error', 
                'message' => 'Database preparation failed'
            ];
        }
    }
}
 
if ($successCount > 0) {
    $update = $conn->prepare("UPDATE rooms SET last_active = NOW() WHERE code = ?");
    if ($update) {
        $update->bind_param("s", $room);
        $update->execute();
        $update->close();
    }
}
 
$response = [
    'status' => $successCount > 0 ? ($errorCount > 0 ? 'partial' : 'success') : 'error',
    'message' => "Uploaded {$successCount} file(s), {$errorCount} failed",
    'details' => $uploadResults,
    'success_count' => $successCount,
    'error_count' => $errorCount,
    'total_files' => count($files['name'])
];
 
ob_end_clean();
echo json_encode($response);
exit; 

function getUploadError($errorCode) {
    switch ($errorCode) {
        case UPLOAD_ERR_INI_SIZE:
        case UPLOAD_ERR_FORM_SIZE:
            return 'File too large';
        case UPLOAD_ERR_PARTIAL:
            return 'File only partially uploaded';
        case UPLOAD_ERR_NO_FILE:
            return 'No file was uploaded';
        case UPLOAD_ERR_NO_TMP_DIR:
            return 'Missing temporary folder';
        case UPLOAD_ERR_CANT_WRITE:
            return 'Failed to write file to disk';
        case UPLOAD_ERR_EXTENSION:
            return 'File upload stopped by extension';
        default:
            return 'Unknown upload error';
    }
}
?>