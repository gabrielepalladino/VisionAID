<?php
// login.php
if (session_status() === PHP_SESSION_NONE)
    session_start();

// Se già loggato, vai alla dashboard
if (isset($_SESSION['user_id'])) {
    header('Location: pages/dashboard.php');
    exit;
}

require_once 'app/config/database.php';
require_once 'app/auth/auth.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($email && $password) {
        $user = loginUser($email, $password);
        if ($user) {
            $_SESSION['user_id'] = $user['admin_id'];
            $_SESSION['user_nome'] = $user['email'];
            $_SESSION['user_email'] = $user['email'];
            $_SESSION['user_ruolo'] = 'admin';
            header('Location: pages/dashboard.php');
            exit;
        } else {
            $error = 'Email o password non corretti.';
        }
    } else {
        $error = 'Compila tutti i campi.';
    }
}
?>
<!DOCTYPE html>
<html lang="it">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accedi — TicketDesk</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link
        href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap"
        rel="stylesheet">
    <link rel="stylesheet" href="styles/log.css">
    <style>
        input[type="text"] {
            width: 100%;
            background: var(--bg);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 12px 44px 12px 16px;
            color: var(--text);
            font-family: 'DM Sans', sans-serif;
            font-size: 15px;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }
    </style>
</head>

<body>
    <div class="grid-bg"></div>

    <div class="login-wrap">
        <div class="brand">
            <div class="brand-icon">
                <svg viewBox="0 0 24 24">
                    <path
                        d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-2 12H6v-2h12v2zm0-3H6V9h12v2zm0-3H6V6h12v2z" />
                </svg>
            </div>
            <h1>Vision<span>AID</span></h1>
            <p>Sistema di gestione ticket</p>
        </div>

        <div class="card">
            <?php if ($error): ?>
                <div class="alert-error">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path
                            d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" />
                    </svg>
                    <?= htmlspecialchars($error) ?>
                </div>
            <?php endif; ?>

            <form method="POST" autocomplete="on">
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" value="<?= htmlspecialchars($_POST['email'] ?? '') ?>"
                        placeholder="nome@azienda.it" required autofocus>
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <div class="input-eye-wrap">
                        <input type="password" id="password" name="password" placeholder="••••••••" required>
                        <button type="button" class="btn-eye" id="togglePassword" aria-label="Mostra/nascondi password">
                            <!-- Icona occhio aperto -->
                            <svg id="eyeOpen" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                <circle cx="12" cy="12" r="3"/>
                            </svg>
                            <!-- Icona occhio sbarrato (nascosta di default) -->
                            <svg id="eyeOff" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:none">
                                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                                <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                                <line x1="1" y1="1" x2="23" y2="23"/>
                            </svg>
                        </button>
                    </div>
                </div>
                <button type="submit" class="btn-login">Accedi →</button>
            </form>
        </div>
    </div>

    <script>
        const togglePassword = document.getElementById('togglePassword');
        const passwordInput = document.getElementById('password');
        const eyeOpen = document.getElementById('eyeOpen');
        const eyeOff = document.getElementById('eyeOff');

        togglePassword.addEventListener('click', () => {
            const isHidden = passwordInput.type === 'password';
            passwordInput.type = isHidden ? 'text' : 'password';
            eyeOpen.style.display = isHidden ? 'none' : 'block';
            eyeOff.style.display = isHidden ? 'block' : 'none';
        });
    </script>
</body>

</html>