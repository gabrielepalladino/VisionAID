<?php
// pages/tickets.php
require_once '../app/auth/auth.php';
checkAuth();

$db   = getDB();
$user = currentUser();

// Filtri
$cerca       = $_GET['cerca']       ?? '';
$stato       = $_GET['stato']       ?? '';
$user_id     = $_GET['user_id']     ?? '';
$resolved_by = $_GET['resolved_by'] ?? '';
$data_da     = $_GET['data_da']     ?? '';
$data_a      = $_GET['data_a']      ?? '';
$res_da      = $_GET['res_da']      ?? '';
$res_a       = $_GET['res_a']       ?? '';

$where  = ['1=1'];
$params = [];

if ($stato) {
    $where[] = 't.status = ?';
    $params[] = $stato;
}
if ($cerca) {
    $where[] = '(t.ticket_id LIKE ? OR t.subject LIKE ? OR t.message LIKE ?)';
    $params  = array_merge($params, ["%$cerca%", "%$cerca%", "%$cerca%"]);
}
if ($user_id) {
    $where[] = 't.user_id = ?';
    $params[] = $user_id;
}
if ($resolved_by) {
    $where[] = 't.resolved_by = ?';
    $params[] = $resolved_by;
}
if ($data_da) {
    $where[] = 't.created_at >= ?';
    $params[] = $data_da . ' 00:00:00';
}
if ($data_a) {
    $where[] = 't.created_at <= ?';
    $params[] = $data_a . ' 23:59:59';
}
if ($res_da) {
    $where[] = 't.resolved_at >= ?';
    $params[] = $res_da . ' 00:00:00';
}
if ($res_a) {
    $where[] = 't.resolved_at <= ?';
    $params[] = $res_a . ' 23:59:59';
}

$sql = "SELECT 
            t.*,
            u.email AS richiedente_email
        FROM support_tickets t
        LEFT JOIN users u ON t.user_id = u.user_id
        WHERE " . implode(' AND ', $where) . "
        ORDER BY t.created_at DESC";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$tickets = $stmt->fetchAll();

$filtri_attivi = $stato || $cerca || $user_id || $resolved_by || $data_da || $data_a || $res_da || $res_a;
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ticket — TicketDesk</title>
    <link rel="stylesheet" href="../styles/dashboard.css">
    <link rel="stylesheet" href="../styles/sidebar.css"/>
    <style>
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
        .date-range input {
            flex: 1;
        }
        .date-range span {
            font-size: 12px;
            color: var(--muted);
            flex-shrink: 0;
        }
        /* color-scheme per input date */
        input[type="date"] {
            color-scheme: light;
        }
        [data-theme="dark"] input[type="date"] {
            color-scheme: dark;
        }
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

        /* ── Custom select ── */
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
            /* tema chiaro default */
            background: #ffffff;
            color: #18181b;
        }
        [data-theme="dark"] .custom-select-trigger {
            background: #25252c;
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
            /* tema chiaro default */
            background: #ffffff;
            box-shadow: 0 8px 24px rgba(0,0,0,.12);
        }
        [data-theme="dark"] .custom-select-dropdown {
            background: #25252c;
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
            /* tema chiaro default */
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
        [data-theme="dark"] .custom-select-trigger {
            background: #1C1C21;
            border-color: var(--border);
        }
    </style>
</head>
<body>
<div class="app-layout">
    <?php require_once '../app/partials/sidebar.php'; ?>

    <main class="main-content">
        <div class="page-header">
            <div>
                <h1 class="page-title">Tutti i Ticket</h1>
                <p class="page-sub"><?= count($tickets) ?> ticket trovati</p>
            </div>
        </div>

        <!-- Filtri -->
        <div class="card" style="margin-bottom:16px;padding:20px 25px">
            <form method="GET">
                <div class="filters-grid">

                    <div class="filter-group">
                        <label>Cerca (ID ticket, oggetto, messaggio)</label>
                        <input type="text" name="cerca"
                               placeholder="🔍  Cerca..."
                               value="<?= htmlspecialchars($cerca) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Stato</label>
                        <input type="hidden" name="stato" id="stato-value" value="<?= htmlspecialchars($stato) ?>">
                        <div class="custom-select" id="stato-select">
                            <div class="custom-select-trigger" onclick="toggleSelect('stato-select')">
                                <span id="stato-label">
                                    <?php
                                        if ($stato === 'open')   echo 'Aperto';
                                        elseif ($stato === 'closed') echo 'Chiuso';
                                        else echo 'Tutti gli stati';
                                    ?>
                                </span>
                                <span class="arrow">▾</span>
                            </div>
                            <div class="custom-select-dropdown">
                                <div class="custom-select-option <?= $stato === '' ? 'selected' : '' ?>"
                                     onclick="selectOption('stato-select','stato-value','stato-label','','Tutti gli stati')">
                                    Tutti gli stati
                                </div>
                                <div class="custom-select-option <?= $stato === 'open' ? 'selected' : '' ?>"
                                     onclick="selectOption('stato-select','stato-value','stato-label','open','Aperto')">
                                    Aperto
                                </div>
                                <div class="custom-select-option <?= $stato === 'closed' ? 'selected' : '' ?>"
                                     onclick="selectOption('stato-select','stato-value','stato-label','closed','Chiuso')">
                                    Chiuso
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="filter-group">
                        <label>Risolto da</label>
                        <input type="text" name="resolved_by"
                               placeholder="Email operatore..."
                               value="<?= htmlspecialchars($resolved_by) ?>">
                    </div>

                    <div class="filter-group">
                        <label>User ID</label>
                        <input type="text" name="user_id"
                               placeholder="UUID utente..."
                               value="<?= htmlspecialchars($user_id) ?>">
                    </div>

                    <div class="filter-group">
                        <label>Data apertura</label>
                        <div class="date-range">
                            <input type="date" name="data_da" value="<?= htmlspecialchars($data_da) ?>">
                            <span>→</span>
                            <input type="date" name="data_a"  value="<?= htmlspecialchars($data_a) ?>">
                        </div>
                    </div>

                    <div class="filter-group">
                        <label>Data risoluzione</label>
                        <div class="date-range">
                            <input type="date" name="res_da" value="<?= htmlspecialchars($res_da) ?>">
                            <span>→</span>
                            <input type="date" name="res_a"  value="<?= htmlspecialchars($res_a) ?>">
                        </div>
                    </div>

                </div>

                <div class="filters-row">
                    <button type="submit" class="btn btn-primary btn-sm">Filtra</button>
                    <?php if ($filtri_attivi): ?>
                        <a href="tickets.php" class="btn btn-secondary btn-sm" style="color:var(--danger)">✕ Reset filtri</a>
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
                            <th>Ticket ID</th>
                            <th>Oggetto</th>
                            <th>Richiedente</th>
                            <th>Stato</th>
                            <th>Aperto il</th>
                            <th>Risolto il</th>
                            <th>Risolto da</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($tickets)): ?>
                        <tr>
                            <td colspan="8">
                                <div class="empty-state">
                                    <svg width="48" height="48" viewBox="0 0 24 24" fill="var(--muted)">
                                        <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/>
                                    </svg>
                                    <h3>Nessun ticket trovato</h3>
                                    <p>Prova a cambiare i filtri o <a href="nuovo_ticket.php" style="color:var(--accent2)">crea un nuovo ticket</a></p>
                                </div>
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($tickets as $t): ?>
                        <tr>
                            <td class="text-muted text-sm" style="font-family:monospace">
                                <span title="<?= htmlspecialchars($t['ticket_id']) ?>">
                                    #<?= substr($t['ticket_id'], 0, 8) ?>…
                                </span>
                            </td>
                            <td style="max-width:240px">
                                <a href="ticket_detail.php?id=<?= $t['ticket_id'] ?>"
                                   style="color:var(--text);text-decoration:none;font-weight:500;display:block"
                                   onmouseover="this.style.color='var(--accent2)'"
                                   onmouseout="this.style.color='var(--text)'">
                                    <?= htmlspecialchars($t['subject']) ?>
                                </a>
                            </td>
                            <td class="text-sm">
                                <div class="text-muted"><?= htmlspecialchars($t['richiedente_email'] ?? '—') ?></div>
                                <div style="font-family:monospace;font-size:10px;color:var(--muted)" title="<?= htmlspecialchars($t['user_id']) ?>">
                                    <?= substr($t['user_id'], 0, 8) ?>…
                                </div>
                            </td>
                            <td>
                                <span class="badge badge-<?= $t['status'] ?>">
                                    <span class="badge-dot"></span>
                                    <?= $t['status'] === 'open' ? 'Aperto' : 'Chiuso' ?>
                                </span>
                            </td>
                            <td class="text-sm text-muted">
                                <?= date('d/m/Y H:i', strtotime($t['created_at'])) ?>
                            </td>
                            <td class="text-sm text-muted">
                                <?= $t['resolved_at'] ? date('d/m/Y H:i', strtotime($t['resolved_at'])) : '—' ?>
                            </td>
                            <td class="text-sm text-muted">
                                <?= $t['resolved_by'] ? htmlspecialchars($t['resolved_by']) : '—' ?>
                            </td>
                            <td>
                                <a href="ticket_detail.php?id=<?= $t['ticket_id'] ?>"
                                   class="btn btn-secondary btn-sm">Apri</a>
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

<script>
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
</script>
</body>
</html>