<?php
// pages/utenti_tickets.php
require_once '../app/auth/auth.php';
checkAuth();

$db      = getDB();
$user_id = $_GET['user_id'] ?? '';

if (!$user_id) {
    echo json_encode([]);
    exit;
}

$stmt = $db->prepare("
    SELECT ticket_id, subject, status,
           DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') AS created_at
    FROM support_tickets
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT 20
");
$stmt->execute([$user_id]);
echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));