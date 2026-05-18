<?php
// ============================================
// app/auth/auth.php
// Funzioni di autenticazione
// ============================================

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';

/**
 * Verifica se l'utente è loggato, altrimenti reindirizza al login
 */
function checkAuth(): void {
    if (!isset($_SESSION['user_id'])) {
        $depth = substr_count($_SERVER['PHP_SELF'], '/') - 1;
        $base  = str_repeat('../', $depth);
        header('Location: ' . $base . 'gestionale/login.php');
        exit;
    }
}

/**
 * Verifica se l'utente ha un ruolo specifico
 */
function checkRole(string $ruolo): bool {
    return isset($_SESSION['user_ruolo']) && $_SESSION['user_ruolo'] === $ruolo;
}

/**
 * Login: verifica email e password, imposta sessione
 */
function loginUser(string $email, string $password) {
    $db = getDB();
    $stmt = $db->prepare("SELECT * FROM admin_users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password_hash'])) {
        return $user;
    }
    return false;
}

/**
 * Dati utente corrente dalla sessione
 */
function currentUser(): array {
    return [
        'id'    => $_SESSION['user_id']    ?? null,
        'nome'  => $_SESSION['user_nome']  ?? '',
        'email' => $_SESSION['user_email'] ?? '',
        'ruolo' => $_SESSION['user_ruolo'] ?? '',
    ];
}

/**
 * Logout: distrugge la sessione e reindirizza al login
 */
function logoutUser(): void {
    // Svuota tutte le variabili di sessione
    $_SESSION = [];

    // Elimina il cookie di sessione (se esiste)
    if (ini_get("session.use_cookies")) {
        $params = session_get_cookie_params();
        setcookie(
            session_name(),
            '',
            time() - 42000,
            $params["path"],
            $params["domain"],
            $params["secure"],
            $params["httponly"]
        );
    }

    // Distrugge la sessione
    session_destroy();

    // Reindirizza al login
    header("Location: ../../login.php");
    exit;
}