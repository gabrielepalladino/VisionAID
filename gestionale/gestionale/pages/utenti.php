<?php
// pages/utenti.php
require_once '../app/auth/auth.php';
checkAuth();

$db   = getDB();
$user = currentUser();

$success = '';
$error   = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'elimina') {
        $uid = $_POST['uid'] ?? '';
        if ($uid) {
            $db->prepare("DELETE FROM users WHERE user_id = ?")->execute([$uid]);
            $success = 'Utente e relativi dati eliminati.';
        }
    }
}

// Filtri
$f_email       = $_GET['email']       ?? '';
$f_dispositivo = $_GET['dispositivo'] ?? '';
$f_os          = $_GET['os']          ?? '';
$f_app         = $_GET['app']         ?? '';
$f_device_id   = $_GET['device_id']   ?? '';
$f_aperti      = $_GET['aperti']      ?? '';
$f_data_da     = $_GET['data_da']     ?? '';
$f_data_a      = $_GET['data_a']      ?? '';

$having  = [];
$where   = ['1=1'];
$params  = [];

if ($f_email) {
    $where[] = 'u.email LIKE ?';
    $params[] = "%$f_email%";
}
if ($f_dispositivo) {
    $where[] = 'u.device_model LIKE ?';
    $params[] = "%$f_dispositivo%";
}
if ($f_os) {
    $where[] = 'u.os = ?';
    $params[] = $f_os;
}
if ($f_app) {
    $where[] = 'u.app_version LIKE ?';
    $params[] = "%$f_app%";
}
if ($f_device_id) {
    $where[] = 'd.internal_device_id LIKE ?';
    $params[] = "%$f_device_id%";
}
if ($f_aperti === '1') {
    $having[] = 'ticket_aperti > 0';
}
if ($f_data_da) {
    $where[] = 't.created_at >= ?';
    $params[] = $f_data_da . ' 00:00:00';
}
if ($f_data_a) {
    $where[] = 't.created_at <= ?';
    $params[] = $f_data_a . ' 23:59:59';
}

$having_sql = $having ? 'HAVING ' . implode(' AND ', $having) : '';

$sql = "
    SELECT 
        u.*,
        d.internal_device_id AS device_id,
        d.firmware_version,
        d.linked_at          AS device_linked_at,
        COUNT(t.ticket_id)                                    AS n_ticket,
        MAX(t.created_at)                                     AS ultimo_ticket,
        SUM(CASE WHEN t.status = 'open'   THEN 1 ELSE 0 END) AS ticket_aperti,
        SUM(CASE WHEN t.status = 'closed' THEN 1 ELSE 0 END) AS ticket_chiusi
    FROM users u
    LEFT JOIN devices d ON d.user_id = u.user_id
    LEFT JOIN support_tickets t ON t.user_id = u.user_id
    WHERE " . implode(' AND ', $where) . "
    GROUP BY u.user_id, d.internal_device_id, d.firmware_version, d.linked_at
    $having_sql
    ORDER BY ultimo_ticket DESC
";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$utenti = $stmt->fetchAll();

$filtri_attivi = $f_email || $f_dispositivo || $f_os || $f_app || $f_device_id || $f_aperti || $f_data_da || $f_data_a;
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Utenti — Gestionale</title>
    <link rel="stylesheet" href="../styles/dashboard.css">
    <link rel="stylesheet" href="../styles/sidebar.css"/>
    <style>
        /* ── Filtri — identico a tickets.php ── */
        .filters-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-bottom: 16px;
        }
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .filter-group label {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .6px;
            color: var(--muted);
        }
        .filter-group input {
            width: 100%;
            height: 38px;
            padding: 0 12px;
            border-radius: 8px;
            border: 1px solid var(--border);
            background: var(--surface2);
            color: var(--text);
            font-size: 13px;
            box-sizing: border-box;
            transition: border-color .2s, background .2s;
        }
        .filter-group input:focus {
            outline: none;
            border-color: var(--accent2);
        }
        .filter-group input::placeholder {
            color: var(--muted);
        }
        .date-range {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .date-range input { flex: 1; }
        .date-range span {
            font-size: 12px;
            color: var(--muted);
            flex-shrink: 0;
        }
        input[type="date"] { color-scheme: light; }
        [data-theme="dark"] input[type="date"] { color-scheme: dark; }
        .filters-row {
            display: flex;
            gap: 8px;
            align-items: center;
            margin-top: 4px;
        }
        .filter-active-tag {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: var(--accent-g);
            color: #fff;
            font-size: 11px;
            font-weight: 600;
            padding: 3px 10px;
            border-radius: 20px;
        }

        /* ── Custom select — identico a tickets.php ── */
        .custom-select {
            position: relative;
            width: 100%;
        }
        .custom-select-trigger {
            height: 38px;
            padding: 0 36px 0 12px;
            border-radius: 8px;
            border: 1px solid var(--border);
            font-size: 13px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: border-color .2s, background .2s;
            user-select: none;
            background: #ffffff;
            color: #18181b;
        }
        [data-theme="dark"] .custom-select-trigger {
            background: #1C1C21;
            color: var(--text);
            border-color: var(--border);
        }
        .custom-select-trigger:hover,
        .custom-select.open .custom-select-trigger {
            border-color: var(--accent2);
        }
        .custom-select-trigger .arrow {
            font-size: 12px;
            color: var(--muted);
            transition: transform .2s;
            flex-shrink: 0;
        }
        .custom-select.open .custom-select-trigger .arrow {
            transform: rotate(180deg);
        }
        .custom-select-dropdown {
            display: none;
            position: absolute;
            top: calc(100% + 4px);
            left: 0;
            right: 0;
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
            z-index: 200;
            background: #ffffff;
            box-shadow: 0 8px 24px rgba(0,0,0,.12);
        }
        [data-theme="dark"] .custom-select-dropdown {
            background: #1C1C21;
            box-shadow: 0 8px 24px rgba(0,0,0,.35);
        }
        .custom-select.open .custom-select-dropdown {
            display: block;
        }
        .custom-select-option {
            padding: 10px 14px;
            font-size: 13px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: background .15s;
            color: #18181b;
        }
        [data-theme="dark"] .custom-select-option {
            color: var(--text);
        }
        .custom-select-option:hover {
            background: #f4f4f5;
        }
        [data-theme="dark"] .custom-select-option:hover {
            background: #37373d;
        }
        .custom-select-option.selected {
            color: var(--accent2);
            font-weight: 600;
        }
        .custom-select-option.selected::after {
            content: '✓';
            margin-left: auto;
            font-size: 12px;
        }

        /* ── Modal ── */
        .modal-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.55);
            z-index: 300;
            align-items: center;
            justify-content: center;
            backdrop-filter: blur(4px);
        }
        .modal-overlay.open { display: flex; }
        .modal {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 28px;
            width: 560px;
            max-width: 95vw;
            max-height: 85vh;
            overflow-y: auto;
            animation: fadeUp .2s ease;
        }
        @keyframes fadeUp {
            from { opacity:0; transform:translateY(12px); }
            to   { opacity:1; transform:translateY(0); }
        }
        .modal-title { font-size: 17px; font-weight: 700; margin-bottom: 20px; }
        .meta-row {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            padding: 9px 0;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
            gap: 12px;
        }
        .meta-row:last-child { border-bottom: none; }
        .meta-label { color: var(--muted); white-space: nowrap; }
        .meta-value { text-align: right; word-break: break-all; }
        .ticket-list { margin-top: 4px; }
        .ticket-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid var(--border);
            gap: 12px;
            font-size: 13px;
        }
        .ticket-row:last-child { border-bottom: none; }
        .ticket-row a { color: var(--text); text-decoration: none; font-weight: 500; }
        .ticket-row a:hover { color: var(--accent2); }
        .stat-row {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            margin-bottom: 20px;
        }
        .stat-box {
            background: var(--surface2);
            border-radius: 10px;
            padding: 12px;
            text-align: center;
        }
        .stat-box .stat-val { font-size: 22px; font-weight: 700; line-height: 1; }
        .stat-box .stat-lbl {
            font-size: 11px;
            color: var(--muted);
            margin-top: 4px;
            text-transform: uppercase;
            letter-spacing: .5px;
        }
    </style>
</head>
<body>
<div class="app-layout">
    <?php require_once '../app/partials/sidebar.php'; ?>

    <main class="main-content">
        <div class="page-header">
            <div>
                <h1 class="page-title">Utenti</h1>
                <p class="page-sub"><?= count($utenti) ?> utenti trovati</p>
            </div>
        </div>

        <?php if ($success): ?>
            <div class="alert alert-success"><?= htmlspecialchars($success) ?></div>
        <?php endif; ?>
        <?php if ($error): ?>
            <div class="alert alert-error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <!-- Filtri -->
        <div class="card" style="margin-bottom:16px;padding:20px 25px">
            <form method="GET">
                <div class="filters-grid">

                    <div class="filter-group" style="grid-column: span 2">
                        <label>Email</label>
                        <input type="text" name="email"
                               placeholder="🔍  Cerca per email..."
                               value="<?= htmlspecialchars($f_email) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Dispositivo</label>
                        <input type="text" name="dispositivo"
                               placeholder="Modello dispositivo..."
                               value="<?= htmlspecialchars($f_dispositivo) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Sistema operativo</label>
                        <input type="hidden" name="os" id="os-value" value="<?= htmlspecialchars($f_os) ?>">
                        <div class="custom-select" id="os-select">
                            <div class="custom-select-trigger" onclick="toggleSelect('os-select')">
                                <span id="os-label">
                                    <?php
                                        if ($f_os === 'android')    echo 'Android';
                                        elseif ($f_os === 'ios')    echo 'iOS';
                                        elseif ($f_os === 'other')  echo 'Altro';
                                        else echo 'Tutti';
                                    ?>
                                </span>
                                <span class="arrow">▾</span>
                            </div>
                            <div class="custom-select-dropdown">
                                <div class="custom-select-option <?= $f_os === '' ? 'selected' : '' ?>"
                                     onclick="selectOption('os-select','os-value','os-label','','Tutti')">
                                    Tutti
                                </div>
                                <div class="custom-select-option <?= $f_os === 'android' ? 'selected' : '' ?>"
                                     onclick="selectOption('os-select','os-value','os-label','android','Android')">
                                    Android
                                </div>
                                <div class="custom-select-option <?= $f_os === 'ios' ? 'selected' : '' ?>"
                                     onclick="selectOption('os-select','os-value','os-label','ios','iOS')">
                                    iOS
                                </div>
                                <div class="custom-select-option <?= $f_os === 'other' ? 'selected' : '' ?>"
                                     onclick="selectOption('os-select','os-value','os-label','other','Altro')">
                                    Altro
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="filter-group">
                        <label>Versione app</label>
                        <input type="text" name="app"
                               placeholder="es. 1.2.3..."
                               value="<?= htmlspecialchars($f_app) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Device ID</label>
                        <input type="text" name="device_id"
                               placeholder="ID dispositivo..."
                               value="<?= htmlspecialchars($f_device_id) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Ticket aperti</label>
                        <input type="hidden" name="aperti" id="aperti-value" value="<?= htmlspecialchars($f_aperti) ?>">
                        <div class="custom-select" id="aperti-select">
                            <div class="custom-select-trigger" onclick="toggleSelect('aperti-select')">
                                <span id="aperti-label">
                                    <?= $f_aperti === '1' ? 'Solo con ticket aperti' : 'Tutti' ?>
                                </span>
                                <span class="arrow">▾</span>
                            </div>
                            <div class="custom-select-dropdown">
                                <div class="custom-select-option <?= $f_aperti === '' ? 'selected' : '' ?>"
                                     onclick="selectOption('aperti-select','aperti-value','aperti-label','','Tutti')">
                                    Tutti
                                </div>
                                <div class="custom-select-option <?= $f_aperti === '1' ? 'selected' : '' ?>"
                                     onclick="selectOption('aperti-select','aperti-value','aperti-label','1','Solo con ticket aperti')">
                                    Solo con ticket aperti
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="filter-group">
                        <label>Ultimo ticket</label>
                        <div class="date-range">
                            <input type="date" name="data_da" value="<?= htmlspecialchars($f_data_da) ?>">
                            <span>→</span>
                            <input type="date" name="data_a"  value="<?= htmlspecialchars($f_data_a) ?>">
                        </div>
                    </div>

                </div>

                <div class="filters-row">
                    <button type="submit" class="btn btn-primary btn-sm">Filtra</button>
                    <?php if ($filtri_attivi): ?>
                        <a href="utenti.php" class="btn btn-secondary btn-sm" style="color:var(--danger)">✕ Reset filtri</a>
                    <?php endif; ?>
                </div>
            </form>
        </div>

        <!-- Tabella -->
        <div class="card">
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Email</th>
                            <th>Dispositivo</th>
                            <th>OS</th>
                            <th>Versione app</th>
                            <th>Device ID</th>
                            <th>Ticket totali</th>
                            <th>Aperti</th>
                            <th>Ultimo ticket</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($utenti)): ?>
                        <tr>
                            <td colspan="9">
                                <div class="empty-state">
                                    <h3>Nessun utente trovato</h3>
                                </div>
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($utenti as $u): ?>
                        <tr>
                            <td>
                                <div style="display:flex;align-items:center;gap:10px">
                                    <div style="width:30px;height:30px;border-radius:50%;background:var(--accent-g);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;flex-shrink:0">
                                        <?= strtoupper(substr($u['email'], 0, 1)) ?>
                                    </div>
                                    <span style="font-weight:500;font-size:13px"><?= htmlspecialchars($u['email']) ?></span>
                                </div>
                            </td>
                            <td class="text-sm text-muted"><?= htmlspecialchars($u['device_model'] ?? '—') ?></td>
                            <td class="text-sm">
                                <?php
                                    $os_labels = ['android' => 'Android', 'ios' => 'iOS', 'other' => 'Altro'];
                                    echo $os_labels[$u['os']] ?? '—';
                                ?>
                            </td>
                            <td class="text-sm text-muted">
                                <?= $u['app_version'] ? 'v' . htmlspecialchars($u['app_version']) : '—' ?>
                            </td>
                            <td class="text-sm text-muted" style="font-family:monospace;font-size:11px">
                                <?= $u['device_id'] ? htmlspecialchars($u['device_id']) : '—' ?>
                            </td>
                            <td class="text-sm"><?= $u['n_ticket'] ?></td>
                            <td class="text-sm">
                                <?php if ($u['ticket_aperti'] > 0): ?>
                                    <span style="color:var(--danger);font-weight:600"><?= $u['ticket_aperti'] ?></span>
                                <?php else: ?>
                                    <span class="text-muted">0</span>
                                <?php endif; ?>
                            </td>
                            <td class="text-sm text-muted">
                                <?= $u['ultimo_ticket'] ? date('d/m/Y H:i', strtotime($u['ultimo_ticket'])) : '—' ?>
                            </td>
                            <td>
                                <div style="display:flex;gap:6px">
                                    <button class="btn btn-secondary btn-sm"
                                            onclick="apriDettaglio(<?= htmlspecialchars(json_encode($u), ENT_QUOTES) ?>)">
                                        Dettaglio
                                    </button>
                                    <form method="POST" style="display:inline"
                                          onsubmit="return confirm('Eliminare questo utente e tutti i suoi ticket?')">
                                        <input type="hidden" name="action" value="elimina">
                                        <input type="hidden" name="uid" value="<?= htmlspecialchars($u['user_id']) ?>">
                                        <button type="submit" class="btn btn-secondary btn-sm"
                                                style="color:var(--danger)">Elimina</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<!-- Modal dettaglio utente -->
<div class="modal-overlay" id="modal-dettaglio"
     onclick="if(event.target===this)this.classList.remove('open')">
    <div class="modal">
        <h2 class="modal-title" id="modal-email">—</h2>

        <div class="stat-row">
            <div class="stat-box">
                <div class="stat-val" id="modal-n-ticket">—</div>
                <div class="stat-lbl">Ticket totali</div>
            </div>
            <div class="stat-box">
                <div class="stat-val" id="modal-aperti" style="color:var(--danger)">—</div>
                <div class="stat-lbl">Aperti</div>
            </div>
            <div class="stat-box">
                <div class="stat-val" id="modal-chiusi" style="color:var(--success)">—</div>
                <div class="stat-lbl">Chiusi</div>
            </div>
        </div>

        <div style="margin-bottom:20px">
            <div style="font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);margin-bottom:8px">
                Dispositivo
            </div>
            <div class="meta-row">
                <div class="meta-label">Sistema operativo</div>
                <div class="meta-value" id="modal-os">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Modello</div>
                <div class="meta-value" id="modal-device-model">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Versione app</div>
                <div class="meta-value" id="modal-app-version">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Device ID</div>
                <div class="meta-value" id="modal-device-id" style="font-family:monospace;font-size:11px">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Firmware</div>
                <div class="meta-value" id="modal-firmware">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">Collegato il</div>
                <div class="meta-value" id="modal-linked-at">—</div>
            </div>
            <div class="meta-row">
                <div class="meta-label">User ID</div>
                <div class="meta-value" id="modal-user-id" style="font-family:monospace;font-size:11px">—</div>
            </div>
        </div>

        <div>
            <div style="font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);margin-bottom:8px">
                Ticket recenti
            </div>
            <div class="ticket-list" id="modal-tickets">
                <div class="text-muted text-sm">Caricamento...</div>
            </div>
        </div>

        <div style="display:flex;justify-content:flex-end;margin-top:20px">
            <button class="btn btn-secondary"
                    onclick="document.getElementById('modal-dettaglio').classList.remove('open')">
                Chiudi
            </button>
        </div>
    </div>
</div>

<script>
/* ── Custom select — identico a tickets.php ── */
function toggleSelect(id) {
    const el = document.getElementById(id);
    const isOpen = el.classList.contains('open');
    document.querySelectorAll('.custom-select.open').forEach(s => s.classList.remove('open'));
    if (!isOpen) el.classList.add('open');
}

function selectOption(selectId, inputId, labelId, value, label) {
    document.getElementById(inputId).value = value;
    document.getElementById(labelId).textContent = label;
    document.querySelectorAll('#' + selectId + ' .custom-select-option').forEach(opt => {
        opt.classList.remove('selected');
    });
    event.currentTarget.classList.add('selected');
    document.getElementById(selectId).classList.remove('open');
}

document.addEventListener('click', function(e) {
    if (!e.target.closest('.custom-select')) {
        document.querySelectorAll('.custom-select.open').forEach(s => s.classList.remove('open'));
    }
});

/* ── Modal dettaglio ── */
function apriDettaglio(u) {
    const os_map = { android: 'Android', ios: 'iOS', other: 'Altro' };

    document.getElementById('modal-email').textContent        = u.email;
    document.getElementById('modal-n-ticket').textContent     = u.n_ticket;
    document.getElementById('modal-aperti').textContent       = u.ticket_aperti;
    document.getElementById('modal-chiusi').textContent       = u.ticket_chiusi;
    document.getElementById('modal-os').textContent           = os_map[u.os] ?? '—';
    document.getElementById('modal-device-model').textContent = u.device_model ?? '—';
    document.getElementById('modal-app-version').textContent  = u.app_version ? 'v' + u.app_version : '—';
    document.getElementById('modal-device-id').textContent    = u.device_id ?? '—';
    document.getElementById('modal-firmware').textContent     = u.firmware_version ?? '—';
    document.getElementById('modal-linked-at').textContent    = u.device_linked_at
        ? new Date(u.device_linked_at).toLocaleString('it-IT') : '—';
    document.getElementById('modal-user-id').textContent      = u.user_id;

    const ticketBox = document.getElementById('modal-tickets');
    ticketBox.innerHTML = '<div class="text-muted text-sm">Caricamento...</div>';

    fetch('utenti_tickets.php?user_id=' + encodeURIComponent(u.user_id))
        .then(r => r.json())
        .then(tickets => {
            if (!tickets.length) {
                ticketBox.innerHTML = '<div class="text-muted text-sm">Nessun ticket.</div>';
                return;
            }
            ticketBox.innerHTML = tickets.map(t => `
                <div class="ticket-row">
                    <div>
                        <a href="ticket_detail.php?id=${t.ticket_id}">${escHtml(t.subject)}</a>
                        <div style="font-size:11px;color:var(--muted);margin-top:2px">${t.created_at}</div>
                    </div>
                    <span class="badge badge-${t.status}">
                        <span class="badge-dot"></span>
                        ${t.status === 'open' ? 'Aperto' : 'Chiuso'}
                    </span>
                </div>
            `).join('');
        })
        .catch(() => {
            ticketBox.innerHTML = '<div class="text-muted text-sm">Errore nel caricamento.</div>';
        });

    document.getElementById('modal-dettaglio').classList.add('open');
}

function escHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
</body>
</html>